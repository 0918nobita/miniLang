type location = { line : int; chr : int }

let string_of_loc loc = string_of_int (loc.line + 1) ^ ":" ^ string_of_int (loc.chr + 1)

let plus_loc base diff = {
  line = base.line + diff.line;
  chr = if diff.line >= 1 then diff.chr else base.chr + diff.chr
}

type 'a result = { ast : 'a; loc : location ; rest : string }

type 'a parser = Parser of (location * string -> 'a result list)

let parse (Parser p) = p

let substr str start len =
  let str_len = String.length str in
    if str_len >= start + len
      then Some (String.sub str start len)
      else None

let token tok =
  let length = String.length tok in
  Parser (fun (loc, src) ->
    match substr src 0 length with
      | Some cut when cut = tok ->
          let lines = String.split_on_char '\n' tok in
          [{
            ast = (loc, cut);
            loc = plus_loc loc {
              line = List.length lines - 1;
              chr = String.length @@ Base.List.last_exn lines
            };
            rest = String.sub src length (String.length src - length)
          }]
      | _ -> [])

let ( <$> ) f p = Parser (fun input ->
  List.map (fun result ->
    { result with ast = f result.ast }) @@ (parse p) input)

let ( <*> ) precede succeed =
  Parser (fun input ->
    Base.List.concat_map (parse precede input) ~f:(function { ast = f; loc = precede_loc; rest } ->
      parse succeed (precede_loc, rest)
      |> List.map (fun result -> { result with ast = f result.ast })))

let return ast = Parser (fun (loc, rest) -> [{ ast; loc; rest }])

let ( >>= ) p f =
  Parser (fun input ->
    Base.List.concat_map (parse p input) ~f:(function { ast; loc; rest } ->
      parse (f ast) (loc, rest)))

let ( >> ) m f = m >>= fun _ -> f

let ( <|> ) p q =
  Parser (fun input ->
    let result = parse p input in
    if List.length result = 0
      then parse q input
      else result)

let item = Parser (fun (loc, src) ->
  match src with
    | "" -> []
    | s ->
        let c = String.(get (sub s 0 1) 0) in
        [{
          ast = (loc, c);
          loc =
            plus_loc loc
            @@ if c = '\n'
              then { line = 1; chr = 0 }
              else { line = 0; chr = 1 };
          rest = String.(sub s 1 (length s - 1))
        }])

let mzero = Parser (fun _ -> [])

let satisfy f = item >>= (fun c -> if f c then return c else mzero)

let char c = satisfy (fun (_, c') -> c = c')

let oneOf cs = satisfy (fun (_, c') -> String.contains cs c')

let option default p = p <|> return default

let ( <~> ) p q = p >>= fun r -> q >>= fun rs -> return (r :: rs)

let rec many p = option [] (p >>= fun r -> many p >>= fun rs -> return (r :: rs))

let some p = p <~> many p

let drop p = p >> return ()
