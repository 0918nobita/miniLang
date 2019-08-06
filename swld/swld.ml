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
