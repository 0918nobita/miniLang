open Parser_combinator

let digit_char = oneOf "0123456789"

let letter = satisfy (fun (_, c) ->
  let code = Char.code c in
    (65 <= code && code <= 90) || (97 <= code && code <= 122))

let identifier =
  (fun (loc, c) results -> (loc, Base.String.of_char_list (c :: List.map snd results)))
  <$> letter
  <*> (many (letter <|> digit_char))

let spaces = some @@ char ' '

let spaces_opt = many @@ char ' '

let newline = char '\n'

let unary =
  let
    plus = char '+' >> return (fun x -> x) and
    minus = char '-' >>= (fun (loc, _) -> return (fun (_, x) -> (loc, (-1) * x)))
  in
    plus <|> minus <|> return (fun x -> x)

let nat =
  let
    digit = (fun (_, c) -> int_of_char c - 48) <$> digit_char and
    toNum x acc = x * 10 + acc
  in
  Parser (function (loc, _) as input ->
    parse (some digit) input
    |> List.map (fun result ->
      { result with ast = (loc, List.fold_left toNum 0 result.ast) }))

let integer = unary <*> nat

type ident = location * string

type inst_ast =
  | I32_const of location * (location * int)

type stmt_ast =
  | Global_def of location * ident * (inst_ast list)
  | Func_def of location * ident * (inst_ast list)

let instruction = Parser (function (loc, _) as input ->
  input
  |> parse (
    spaces_opt
    >> token "i32.const"
    >> spaces
    >> integer
    >>= (fun num ->
      spaces_opt
      >> newline
      >> return @@ I32_const (loc, num))))

let empty_line = drop (many (char ' ') >> newline)

let func_def = Parser (function (loc, _) as input ->
  input
  |> parse (
    token "function"
    >> spaces
    >> identifier
    >>= (fun ident ->
      spaces_opt
      >> newline
      >> many instruction
      >>= (fun insts ->
        spaces_opt
        >> token "endfunction"
        >> spaces_opt
        >> newline
        >> many empty_line
        >> return @@ Func_def (loc, ident, insts)))))

let global_def = Parser (function (loc, _) as input ->
  input
  |> parse (
    token "global"
    >> spaces
    >> identifier
    >>= (fun ident ->
      spaces_opt
      >> newline
      >> many instruction
      >>= (fun insts ->
        spaces_opt
        >> token "endglobal"
        >> spaces_opt
        >> newline
        >> many empty_line
        >> return @@ Global_def (loc, ident, insts)))))

let program src =
  parse
    (many empty_line >> many (global_def <|> func_def))
    (bof, src)

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
      ()
