open Parser

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

let version = "0.0.2"

let () =
  if Array.length Sys.argv = 1
    then
      begin
        print_endline "SWLD - Segmental WASM Linker";
        print_endline @@ "Version " ^ version
      end
    else
      let stmts = program @@ read Sys.argv.(1) in
      stmts
      |> List.iter (function
        | Func_def { ident; _ } ->
            print_endline @@ snd ident
        | Global_def _ ->
            ())
