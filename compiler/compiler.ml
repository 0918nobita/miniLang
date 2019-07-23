open Parser_combinator

open Parser

open Binary

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

let make_list len elem = Array.to_list @@ Array.make len elem

let write f bytes = List.iter (output_byte f) bytes

let adjust_size size bytes =
  let lack = size - List.length bytes in
    if lack = 0
      then bytes
      else
        if lack > 0
          then bytes @ make_list lack 0
          else failwith "(adjust_arr_length) Invalid format"

exception Duplicate_export of location

let check_duplication =
  let rec inner checked = function
    | [] -> ()
    | ExportDef (_, (loc, name), _) :: tail ->
        if List.mem name checked
          then raise @@ Duplicate_export loc
          else inner (name :: checked) tail
  in
    inner []

let concatMap f list = List.(concat @@ map f list)

let functions_of_stmts = List.map (function
  ExportDef (_, (_, name), expr_ast) ->
    let max = ref (-1) in
    let code = (Ir.bin_of_insts (Ir.insts_of_expr_ast expr_ast) max) in
    let locals = !max + 1 in
    ExportedFunc { export_name = name; signature = { params = 0; results = 1 }; locals; code })

let compile src =
  let ast = program src in
  check_duplication ast;
  let out = open_out "out.wasm" in
  write out @@ bin_of_wasm
    { functions = functions_of_stmts ast
    ; memories = []
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
    print_endline @@ string_of_loc loc ^ ": Duplicate export"
  end

let unbound_value isREPL src loc ident =
  begin
    if isREPL = false then print_endline @@ List.nth (String.split_on_char '\n' src) loc.line;
    print_endline @@ String.make loc.chr ' ' ^ "^";
    print_endline @@ string_of_loc loc ^ ": Unbound value `" ^ ident ^ "`"
  end

let repl () =
  while true do
    let input = read_line () in
    try
      if input = ":quit" || input = ":exit" then exit 0;
      compile @@ input;
      match Sys.command "wasm-interp --run-all-exports ./out.wasm" with
        | 0 -> ()
        | _ -> failwith "wasm-interp との連携に失敗しました"
    with
      | Syntax_error loc ->
          syntax_error true input loc
      | Duplicate_export loc ->
          duplicate_export true input loc
      | Unbound_value (loc, ident) ->
          unbound_value true input loc ident
  done

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
        | "repl" ->
            repl ()
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
                  | Duplicate_export loc ->
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
