let string_rev s =
  let len = String.length s in
  String.init len (fun i -> s.[len - 1 - i])

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

let command str =
  match Sys.command str with
    | 0 -> ()
    | n -> raise @@ Failure ("予期しないエラー" ^ string_of_int n)

type color =
  | Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White

let int_of_color col =
  match col with
    | Black   -> 0
    | Red     -> 1
    | Green   -> 2
    | Yellow  -> 3
    | Blue    -> 4
    | Magenta -> 5
    | Cyan    -> 6
    | White   -> 7

let foreground col text =
  Printf.sprintf "\x1B[3%dm%s\x1B[0m" (int_of_color col) text

let background col text =
  Printf.sprintf "\x1B[4%dm%s\x1B[0m" (int_of_color col) text

let diff name =
  match Sys.command @@ "diff result " ^ name ^ ".snapshot > tmp" with
    | 0 -> print_endline @@ background Green (foreground Black "PASS") ^ " " ^ name ^ ".psy"
    | _ ->
        begin
          print_endline @@ background Red (foreground Black "FAIL") ^ " " ^ name ^ ".psy";
          print_string @@ foreground Red @@ read "tmp";
          exit (-1)
        end

let () =
  (* collect *.psy files *)
  let files =
    Sys.readdir "."
    |> Array.to_list
    |> List.filter (fun file_name ->
      String.length file_name > 4 && String.sub (string_rev file_name) 0 4 = "ysp.")
    |> List.sort compare
  in
  files
  |> List.iter (fun file ->
    let name = String.sub file 0 (String.length file - 4) in
    let out = open_out "result" in
    match Sys.command @@ "psyche " ^ file ^ " > tmp" with
      | 0 ->
          begin match Sys.command "wasm-interp --run-all-exports out.wasm > tmp" with
            | 0 ->
                begin
                  output_string out @@ "Compilation: Success\nOutput:\n" ^ read "tmp";
                  close_out out;
                  command "rm tmp";
                  diff name;
                  command "rm tmp";
                  command "rm result";
                end
            | _ -> raise @@ Failure "(1) 予期しないエラー"
          end
      | 255 ->
          begin
            output_string out @@ "Compilation: Failed\nOutput:\n" ^ read "tmp";
            close_out out;
            command "rm tmp";
            diff name;
            command "rm tmp";
            command "rm result"
          end
      | _ ->
          raise @@ Failure "(2) 予期しないエラー");
  print_endline "\n✨ Complete! "
