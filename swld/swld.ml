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
  | I32_add of location
  | I32_sub of location
  | I32_mul of location
  | I32_div_s of location
  | Decl_local of location * ident
  | Get_local of location * ident
  | Set_local of location * ident

type stmt_ast =
  | Global_def of location * ident * (inst_ast list)
  | Func_def of
    { loc: location
    ; ident: ident
    ; export_name: string option
    ; args: (ident list)
    ; has_ret_val: bool
    ; insts: (inst_ast list)
    }

let empty_line = drop (many (char ' ') >> newline)

let i32_const = Parser (fun input ->
  input
  |> parse (
    spaces_opt
    >> token "i32.const"
    >>= (fun (loc, _) ->
      spaces
      >> integer
      >>= (fun num ->
        spaces_opt
        >> newline
        >> many empty_line
        >> return @@ I32_const (loc, num)))))

let no_args opcode generator =
  Parser (fun input ->
    input
    |> parse (
      spaces_opt
      >> token opcode
      >>= (fun (loc, _) ->
        spaces_opt
        >> newline 
        >> many empty_line
        >> return @@ generator loc)))

let i32_add = no_args "i32.add" (fun loc -> I32_add loc)

let i32_sub = no_args "i32.sub" (fun loc -> I32_sub loc)

let i32_mul = no_args "i32.mul" (fun loc -> I32_mul loc)

let i32_div_s = no_args "i32.div_s" (fun loc -> I32_div_s loc)

let decl_local = Parser (fun input ->
  input
  |> parse (
    spaces_opt
    >> token "decl_local"
    >>= (fun (loc, _) ->
      spaces
      >> identifier
      >>= (fun ident ->
        spaces_opt
        >> newline
        >> many empty_line
        >> return @@ Decl_local (loc, ident)))))

let get_local = Parser (fun input ->
  input
  |> parse (
    spaces_opt
    >> token "get_local"
    >>= (fun (loc, _) ->
      spaces
      >> identifier
      >>= (fun ident ->
        spaces_opt
        >> newline
        >> many empty_line
        >> return @@ Get_local (loc, ident)))))

let set_local = Parser (fun input ->
  input
  |> parse (
    spaces_opt
    >> token "set_local"
    >>= (fun (loc, _) ->
      spaces
      >> identifier
      >>= (fun ident ->
        spaces_opt
        >> newline
        >> many empty_line
        >> return @@ Set_local (loc, ident)))))

let instruction =
  i32_const
  <|> i32_add
  <|> i32_sub
  <|> i32_mul
  <|> i32_div_s
  <|> decl_local
  <|> get_local
  <|> set_local

let str_literal =
  Parser (function (loc, _) as input ->
    input
    |> parse (
      char '"'
      >> identifier
      >>= (fun (_, content) ->
        char '"'
        >> return (loc, content))))

let arg =
  identifier
  >>= (fun ident ->
    spaces
    >> token "i32"
    >> spaces_opt
    >> return ident)

let arguments =
  Parser (fun input ->
    input
    |> parse (
      char '('
      >> spaces_opt
      >> option [] (List.cons
        <$> arg
        <*> many (
          char ','
          >> spaces_opt
          >> arg))
      >>= (fun args ->
        char ')'
        >> spaces_opt
        >> return args)))

let func_def = Parser (function (loc, _) as input ->
  input
  |> parse (
    token "function"
    >> option None (spaces >> (Base.Option.some <$> str_literal))
    >>= (fun export_name ->
      spaces
      >> identifier
      >>= (fun ident ->
        arguments
        >>= (fun args ->
          ((token "i32" >> return true) <|> (token "void" >> return false))
          >>= (fun has_ret_val ->
            spaces_opt
            >> newline
            >> many empty_line
            >> many instruction
            >>= (fun insts ->
              spaces_opt
              >> token "endfunction"
              >> spaces_opt
              >> newline
              >> many empty_line
              >> return @@ Func_def
                { loc
                ; ident
                ; args
                ; has_ret_val
                ; insts
                ; export_name = Base.Option.map export_name ~f:snd
                })))))))

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

exception Syntax_error of location

let program src =
  let result = parse (many empty_line >> many (global_def <|> func_def)) (bof, src) in
  result
    |> List.iter (function
      | { ast = _; loc; rest } when rest <> "" -> raise @@ Syntax_error loc
      | _ -> ());
    (List.hd result).ast

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
