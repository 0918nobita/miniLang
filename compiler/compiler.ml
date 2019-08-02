open Parser_combinator
open Parser
open Ir
open Wasm

let read filename =
	let
    f = open_in filename and
    str = ref ""
  in
    (try
      while true do str := !str ^ input_line f ^ "\n" done;
    with
      _ -> ());
    close_in f;
    !str

let write f bytes = List.iter (output_byte f) bytes

let adjust_size size bytes =
  let lack = size - List.length bytes in
    if lack = 0
      then bytes
      else
        if lack > 0
          then bytes @ Base.List.init lack ~f:(fun _ -> 0)
          else failwith "(adjust_arr_length) Invalid format"

exception Duplicate_func of location

let check_duplication =
  let rec inner checked = function
    | [] -> ()
    | FuncDef (_, _, (loc, name), _, _) :: tail ->
        if List.mem name checked
          then raise @@ Duplicate_func loc
          else inner (name :: checked) tail
  in
    inner []

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
    ; code = [32; 0; 65; 8; 107; 33; 1; 2; 64; 3; 64; 32; 2; 40; 2; 0; 33; 2; 32; 2; 32; 1; 74; 4; 64; 32; 3; 32; 1; 54; 2; 0; 32; 2; 32; 1; 32; 1; 65; 4; 106; 40; 2; 0; 106; 65; 8; 106; 70; 4; 64; 32; 1; 32; 2; 40; 2; 0; 54; 2; 0; 32; 1; 65; 4; 106; 32; 1; 65; 4; 106; 40; 2; 0; 65; 8; 106; 32; 2; 65; 4; 106; 40; 2; 0; 106; 54; 2; 0; 5; 32; 1; 32; 2; 54; 2; 0; 11; 15; 11; 32; 2; 33; 3; 32; 2; 40; 2; 0; 65; 0; 71; 13; 0; 11; 32; 3; 32; 1; 54; 2; 0; 11]
    }
  ; Func (* push *)
    { signature = { params = 1; results = 0}
    ; locals = 0
    ; code =
      [35; 0; 32; 0; 54; 2; 0; 35; 0; 65; 4; 107; 36; 0]
    }
  ; Func (* pop *)
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code = [35; 0; 65; 4; 106; 36; 0; 35; 0; 40; 2; 0]
    }
  ; Func (* top *)
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code = [35; 0; 65; 4; 106; 40; 2; 0]
    }
  ]

let names_of_stmts =
  List.map (function FuncDef (_, _, (_, name), _, _) -> name)

let functions_of_stmts stmts =
  let names = names_of_stmts stmts in
  stmts
  |> List.map (function
    FuncDef (_, pub, ident, args, expr_ast) ->
      let max = ref (-1) in
      let code = (Ir.bin_of_insts (Ir.insts_of_expr_ast expr_ast names args) max (List.length args)) in
      if pub
        then
          ExportedFunc
            { export_name = snd ident
            ; exp_signature = { params = List.length args; results = 1 }
            ; locals = !max + 1 + List.length args
            ; code
            }
        else
          Func
            { signature = { params = List.length args; results = 1 }
            ; locals = !max + 1 + List.length args
            ; code
            })

let compile src =
  let ast = program src in
  check_duplication ast;
  let out = open_out "out.wasm" in
  write out @@ bin_of_wasm
    { global_vars =
      [ Global [65; 255; 243; 3] (* i32.const 63999 *)
      ; ExportedGlobal (ExportedGlobalVar { export_name = "status"; code = [65; 0] (* i32.const 0 *) })
      ]
    ; functions = hidden_functions @ functions_of_stmts ast
    ; memories = [ Mem { limits = false; initial = 1 } ]
    };
  close_out out

let syntax_error isREPL src loc =
  begin
    if isREPL = false then print_endline @@ List.nth (String.split_on_char '\n' src) loc.line;
    print_endline @@ String.make loc.chr ' ' ^ "^";
    print_endline @@ string_of_loc loc ^ ": Syntax Error"
  end

let duplicate_export isREPL src loc =
  begin
    if isREPL = false then print_endline @@ List.nth (String.split_on_char '\n' src) loc.line;
    print_endline @@ String.make loc.chr ' ' ^ "^";
    print_endline @@ string_of_loc loc ^ ": Duplicate function"
  end

let unbound_value isREPL src loc ident =
  begin
    if isREPL = false then print_endline @@ List.nth (String.split_on_char '\n' src) loc.line;
    print_endline @@ String.make loc.chr ' ' ^ "^";
    print_endline @@ string_of_loc loc ^ ": Unbound value `" ^ ident ^ "`"
  end

let () =
  if Array.length Sys.argv = 1
    then
      print_string @@
        "    ____                  __\n" ^
        "   / __ \\_______  _______/ /_  ___\n" ^
        "  / /_/ / ___/ / / / ___/ __ \\/ _ \\\n" ^
        " / ____(__  ) /_/ / /__/ / / /  __/\n" ^
        "/_/   /____/\\__, /\\___/_/ /_/\\___/\n" ^
        "           /____/\n\n" ^
        "A WASM friendly lightweight programming language\n" ^
        "Version 0.0.1\n"
    else
      match Sys.argv.(1) with
        | "make" ->
            if Array.length Sys.argv >= 3
              then
                let input = read @@ Sys.argv.(2) in
                try
                  compile input
                with
                  | Syntax_error loc ->
                      begin
                        syntax_error false input loc;
                        exit (-1)
                      end
                  | Duplicate_func loc ->
                      begin
                        duplicate_export false input loc;
                        exit (-1)
                      end
                  | Unbound_value (loc, ident) ->
                      begin
                        unbound_value false input loc ident;
                        exit (-1)
                      end
              else
                (print_endline "Source files were not provided"; exit (-1))
        | str ->
            (print_endline @@ "Invalid subcommand: " ^ str; exit (-1))
