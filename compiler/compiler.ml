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

let compile src =
  let ast = program src in
  check_duplication ast;
  let out = open_out "out.wasm" in
  write out @@ bin_of_wasm
    { global_vars =
      [ Global [65; 255; 243; 3] (* i32.const 63999 *)
      ; ExportedGlobal (ExportedGlobalVar { export_name = "status"; code = [65; 0] (* i32.const 0 *) })
      ]
    ; functions = Ir.wasm_func_list_of_stmts ~stmts:ast
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
