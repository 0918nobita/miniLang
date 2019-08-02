open Parser_combinator
open Parser

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
  | Call of int
  | GetLocal of int

type context =
  { params : ident list
  ; env : (string * int) list
  ; depth : int
  ; max_depth : int ref
  }

exception Unbound_value of location * string

let insts_of_expr_ast ast names params =
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
    | If (_, cond, t, e) ->
        inner (cond, ctx) @ [I32Eqz; I32If (inner (e, ctx), inner (t, ctx))]
    | Let (_, (_, ident), bound_expr, expr) ->
        let depth = ctx.depth + 1 in
        let () = if depth > !(ctx.max_depth) then ctx.max_depth := depth in
        let ctx_for_bound_expr = { ctx with depth } in
        let ctx_for_expr = { ctx with env = (ident, depth) :: ctx.env; depth } in
        if depth = 0
          then
            Call 5
            :: inner (bound_expr, ctx_for_bound_expr)
            @ I32Store
            :: inner (expr, ctx_for_expr)
          else
            Call 5
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
                  [Call 5; I32Load]
                else
                  [Call 5; I32Const (List.hd addrs * 4);  I32Add; I32Load]
    | Funcall (loc, ident, asts) ->
        begin match Base.List.findi names ~f:(fun _ -> (=) ident) with
          | Some (index, _) ->
              Base.List.concat_map asts ~f:(fun ast -> inner (ast, ctx)) @ [Call (index + 7)]
          | None ->
              raise @@ Unbound_value (loc, ident)
        end
  in
  let max_depth = ref (-1) in
  let body = inner (ast, { env = []; depth = -1; max_depth; params }) in
  if !max_depth > (-1)
    then [I32Const (4 * (!max_depth + 1)); Call 1; Call 3] @ body @ [Call 4; Call 2]
    else body

let bin_of_insts irs max num_params =
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
    | Call n :: tail ->
        16 :: (* opcode *)
        n :: (* function index *)
        inner (tail, current, max)
    | GetLocal n :: tail ->
        32 :: Binary.leb128_of_int n @
        inner (tail, current, max)
  in
    inner (irs, (-1) + num_params, max)
