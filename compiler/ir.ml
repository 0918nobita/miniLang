open Parser_combinator
open Parser
open Wasm
open Wast

type instruction =
  | I32Const of int
  | I32Add
  | I32Sub
  | I32Mul
  | I32DivS
  | I32Eq
  | I32Ne
  | I32Gt
  | I32Ge
  | I32Lt
  | I32Le
  | I32Eqz
  | I32If of instruction list * instruction list
  | I32Local of instruction list
  | TeeLocal of int
  | GetLocalVar of int
  | I32Load
  | I32Store
  | CallFunc of string
  | GetLocal of int

type context =
  { ctx_params : ident list
  ; env : (string * int) list
  ; depth : int
  ; max_depth : int ref
  }

exception Unbound_value of location * string

let insts_of_expr_ast ~expr_ast ~fn_names ~params ~called_internals =
  let rec inner (expr_ast, ctx) = match expr_ast with
    | IntLiteral (_, n) -> [I32Const n]
    | Minus (_, expr) ->
        inner (expr, ctx) @ [I32Const (-1); I32Mul]
    | Add (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Add]
    | Sub (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Sub]
    | Mul (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Mul]
    | Div (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32DivS]
    | Eq (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Eq]
    | Ne (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Ne]
    | Greater (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Gt]
    | GreaterE (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Ge]
    | Less (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Lt]
    | LessE (_, lhs, rhs) ->
        inner (lhs, ctx) @ inner (rhs, ctx) @ [I32Le]
    | And (_, lhs, rhs) ->
        inner (lhs, ctx) @ [I32Eqz; I32If ([I32Const 0], inner (rhs, ctx))]
    | Or (_, lhs, rhs) ->
        inner (lhs, ctx) @ [I32Local [TeeLocal 0; I32Eqz; I32If (inner (rhs, ctx), [GetLocalVar 0])]]
    | IfElse (_, cond, t, e) ->
        inner (cond, ctx) @ [I32Eqz; I32If (inner (e, ctx), inner (t, ctx))]
    | Let (_, (_, ident), bound_expr, expr) ->
        let depth = ctx.depth + 1 in
        let () = if depth > !(ctx.max_depth) then ctx.max_depth := depth in
        let ctx_for_bound_expr = { ctx with depth } in
        let ctx_for_expr = { ctx with env = (ident, depth) :: ctx.env; depth } in
        if depth = 0
          then
            CallFunc "top"
            :: inner (bound_expr, ctx_for_bound_expr)
            @ I32Store
            :: inner (expr, ctx_for_expr)
          else
            CallFunc "top"
            :: I32Const (4 * depth)
            :: I32Add
            :: inner (bound_expr, ctx_for_bound_expr)
            @ I32Store
            :: inner (expr, ctx_for_expr)
    | Ident (loc, name) ->
        let addrs =
          ctx.env
          |> List.filter (fun elem -> fst elem = name)
          |> List.map snd
        in
          if List.length addrs = 0  (* let 束縛されていない場合、引数に含まれていないか確認する *)
            then (
              match Base.List.findi (params |> List.map snd) ~f:(fun _ -> (=) name) with
                | Some (index, _) ->
                    [GetLocal index]
                | None ->
                    raise @@ Unbound_value (loc, name))
            else
              if List.hd addrs = 0
                then
                  [CallFunc "top"; I32Load]
                else
                  [CallFunc "top"; I32Const (List.hd addrs * 4);  I32Add; I32Load]
    | Funcall (loc, ident, asts) ->
        begin match Base.List.exists fn_names ~f:((=) ident) with
          | true ->
              Base.List.concat_map asts ~f:(fun ast -> inner (ast, ctx)) @ [CallFunc ident]
          | false ->
              raise @@ Unbound_value (loc, ident)
        end
  in
  let max_depth = ref (-1) in
  let body = inner (expr_ast, { env = []; depth = -1; max_depth; ctx_params = params }) in
  let check_called_internals =
    let [@warning "-8"] (* Partial match *)
      rec inner list = function
      | [] -> ()
      | CallFunc ident :: tail ->
          if List.exists ((=) ident) list
            then inner list tail
            else called_internals := ident :: (!called_internals)
      | _ :: tail -> inner list tail
    in
    inner []
  in
  let body = if !max_depth > (-1)
    then [I32Const (4 * (!max_depth + 1)); CallFunc "malloc"; CallFunc "push"] @ body @ [CallFunc "pop"; CallFunc "free"]
    else body
  in
  check_called_internals body;
  body

let unwrap = function
  | Some v -> v
  | None -> raise @@ Invalid_argument "Unwrap failure"

let bin_of_insts ~insts ~num_params ~fn_names =
  let rec inner (irs, current, max) = match irs with
    | [] -> []
    | I32Const n :: tail ->
        65 :: Binary.leb128_of_int n @
        inner (tail, current, max)
    | I32Add :: tail ->
        106 :: inner (tail, current, max)
    | I32Sub :: tail ->
        107 :: inner (tail, current, max)
    | I32Mul :: tail ->
        108 :: inner (tail, current, max)
    | I32DivS :: tail ->
        109 :: inner (tail, current, max)
    | I32Eq :: tail ->
        70 :: inner (tail, current, max)
    | I32Ne :: tail ->
        71 :: inner (tail, current, max)
    | I32Gt :: tail ->
        74 :: inner (tail, current, max)
    | I32Ge :: tail ->
        78 :: inner (tail, current, max)
    | I32Lt :: tail ->
        72 :: inner (tail, current, max)
    | I32Le :: tail ->
        76 :: inner (tail, current, max)
    | I32Eqz :: tail ->
        69 :: inner (tail, current, max)
    | I32If (t, e) :: tail ->
        4 (* if *) ::
        127 (* i32 *) ::
        inner (t, current, max) @
        [ 5 (* else *)
        ] @
        inner (e, current, max) @
        [ 11 (* end*)
        ] @
        inner (tail, current, max)
    | I32Local inner_irs :: tail ->
        (if !max = current
          then
            (max := !max + 1;
            inner (inner_irs, current + 1,  max))
          else inner (inner_irs, current + 1, max)) @
        inner (tail, current, max)
    | TeeLocal n :: tail ->
        34 :: Binary.leb128_of_int (n + current) @
        inner (tail, current, max)
    | GetLocalVar n :: tail ->
        32 :: Binary.leb128_of_int (n + current) @
        inner (tail, current, max)
    | I32Load :: tail ->
        40 :: (* opcode *)
        2 :: (* alignment *)
        0 :: (* load offset *)
        inner (tail, current, max)
    | I32Store :: tail ->
        54 :: (* opcode *)
        2 :: (* alignment *)
        0 :: (* store offset *)
        inner (tail, current, max)
    | CallFunc ident :: tail ->
        16 :: (* opcode *)
        fst (unwrap (Base.List.findi fn_names ~f:(fun _ -> (=) ident))) ::
        inner (tail, current, max)
    | GetLocal n :: tail ->
        32 :: Binary.leb128_of_int n @
        inner (tail, current, max)
  in
  let max = ref (-1) in
  (!max, inner (insts, (-1) + num_params, max))

let hidden_functions =
  [ Func (* init *)
    { signature = { params = 0; results = 0}
    ; locals = 0
    ; code = [65; 0; 65; 8; 54; 2; 0; 65; 4; 65; 0; 54; 2; 0; 65; 8; 65; 0; 54; 2; 0; 65; 12; 65; 202; 215; 2; 54; 2; 0]
    }
  ; Func (* malloc *)
    { signature = { params = 1; results = 1}
    ; locals = 4
    ; code = [2; 64; 3; 64; 32; 1; 40; 2; 0; 33; 1; 32; 1; 65; 4; 106; 40; 2; 0; 32; 0; 107; 33; 4; 32; 4; 65; 0; 74; 4; 64; 32; 1; 32; 1; 65; 4; 106; 40; 2; 0; 106; 32; 0; 65; 8; 106; 107; 33; 3; 65; 4; 32; 3; 106; 32; 0; 54; 2; 0; 32; 1; 65; 4; 106; 32; 1; 65; 4; 106; 40; 2; 0; 32; 0; 65; 8; 106; 107; 54; 2; 0; 32; 3; 65; 8; 106; 15; 11; 32; 4; 69; 4; 64; 2; 64; 3; 64; 32; 2; 40; 2; 0; 33; 2; 32; 2; 40; 2; 0; 32; 1; 70; 4; 64; 32; 2; 32; 1; 40; 2; 0; 54; 2; 0; 32; 1; 15; 11; 32; 2; 40; 2; 0; 65; 0; 71; 13; 0; 11; 0; 11; 11; 32; 1; 40; 2; 0; 65; 0; 71; 13; 0; 11; 11; 0]
    }
  ; Func (* free *)
    { signature = { params = 1; results = 0}
    ; locals = 3
    ; code = bin_of_wasm_insts
      [ Set_local (1, [I32_sub ([Get_local 0], [I32_const 8])])
      ; Block Void
        ; Loop Void
          ; Set_local (2, [I32_load [Get_local 2]])
          ; If
            { ret_type = Void
            ; cond = [I32_gt ([Get_local 2], [Get_local 1])]
            ; then_ =
              [ I32_store ([Get_local 3], [Get_local 1])
              ; If_else
                { ret_type = Void
                ; cond =
                  [I32_eq
                    ( [Get_local 2]
                    , [I32_add
                        ( [I32_add (
                            [Get_local 1],
                            [I32_load [I32_add ([Get_local 1], [I32_const 4])]])]
                        , [I32_const 8]
                        )]
                    )
                  ]
                ; then_ =
                  [ I32_store ([Get_local 1], [I32_load [Get_local 2]])
                  ; I32_store
                    ( [I32_add ([Get_local 1], [I32_const 4])]
                    , [I32_add
                        ( [I32_add ([I32_const 8], [I32_load [I32_add ([Get_local 1], [I32_const 4])]])]
                        , [I32_load [I32_add ([Get_local 2], [I32_const 4])]]
                        )]
                    )
                  ]
                ; else_ = [I32_store ([Get_local 1], [Get_local 2])]
                }
              ; Return
              ]
            }
          ; Set_local (3, [Get_local 2])
          ; Br_if (0, [I32_ne ([I32_load [Get_local 2]], [I32_const 0])])
        ; End
        ; I32_store ([Get_local 3], [Get_local 1])
      ; End
      ]
    }
  ; Func (* push *)
    { signature = { params = 1; results = 0}
    ; locals = 0
    ; code = bin_of_wasm_insts
      [ I32_store ([Get_global 0], [Get_local 0])
      ; Set_global (0, [I32_sub ([Get_global 0], [I32_const 4])])
      ]
    }
  ; Func (* pop *)
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code = bin_of_wasm_insts
      [ Set_global (0, [I32_add ([Get_global 0], [I32_const 4])])
      ; I32_load [Get_global 0]
      ]
    }
  ; Func (* top *)
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code = bin_of_wasm_insts [ I32_load [I32_add ([Get_global 0], [I32_const 4])] ]
    }
  ]

let wasm_func_list_of_stmts ~stmts =
  let fn_names =
    ["init"; "malloc"; "free"; "push"; "pop"; "top"]
    @ List.map (function FuncDef (_, _, (_, name), _, _) -> name) stmts
  in
  let called_internals = ref [] in
  let insts_list =
    stmts
    |> List.map (
      function FuncDef (_, pub, ident, params, expr_ast) ->
        ( pub
        , snd ident
        , List.length params
        , insts_of_expr_ast
          ~expr_ast
          ~fn_names
          ~params
          ~called_internals
        ))
  in
  hidden_functions
  @
  (insts_list
  |> List.map (fun (pub, ident, num_params, insts) ->
    let (max, code) = bin_of_insts ~insts ~num_params ~fn_names in
    if pub
      then
        ExportedFunc
          { export_name = ident
          ; exp_signature = { params = num_params; results = 1 }
          ; locals = max + 1 + num_params
          ; code
          }
      else
        Func
          { signature = { params = num_params; results = 1 }
          ; locals = max + 1 + num_params
          ; code
          }))
