open Parser_combinator

type ident = location * string

type expr_ast =
  | IntLiteral of location * int
  | Ident of ident
  | Minus of location * expr_ast
  | Add of location * expr_ast * expr_ast
  | Sub of location * expr_ast * expr_ast
  | Mul of location * expr_ast * expr_ast
  | Div of location * expr_ast * expr_ast
  | Eq of location * expr_ast * expr_ast
  | Ne of location * expr_ast * expr_ast
  | Less of location * expr_ast * expr_ast
  | LessE of location * expr_ast * expr_ast
  | Greater of location * expr_ast * expr_ast
  | GreaterE of location * expr_ast * expr_ast
  | And of location * expr_ast * expr_ast
  | Or of location * expr_ast * expr_ast
  | IfElse of location * expr_ast * expr_ast * expr_ast
  | Let of location * ident * expr_ast * expr_ast
  | Funcall of location * string * (expr_ast list)

type stmt_ast = FuncDef of location * bool * ident * (ident list) * expr_ast

let unary =
  let
    plus = char '+' >> return (fun x -> x) and
    minus = char '-' >>= (fun (loc, _) -> return (fun ast -> Minus (loc, ast)))
  in
    plus <|> minus <|> return (fun x -> x)

let digit_char = oneOf "0123456789"

let nat =
  let
    digit = (fun (_, c) -> int_of_char c - 48) <$> digit_char and
    toNum x acc = x * 10 + acc
  in
  Parser (function (loc, _) as input ->
    parse (some digit) input
    |> List.map (fun result ->
      { result with ast = IntLiteral (loc, List.fold_left toNum 0 result.ast) }))

exception Syntax_error of location

exception Out_of_loop of int * location

let comment =
  token "(*"
  >> Parser (fun (_, src) ->
    let line = ref 0 in
    let chr = ref 0 in
    let nests = ref 1 in
    let asterisk = ref false in
    let left_parenthesis = ref false in
    let (idx, loc) =
      try
        for index = 0 to (String.length src - 1) do
          let c = String.get src index in
            begin match c with
              | '(' ->
                  begin
                    if !asterisk then asterisk := false;
                    if !left_parenthesis = false then left_parenthesis := true;
                  end
              | '*' ->
                  begin
                    if !asterisk = false then asterisk := true;
                    if !left_parenthesis then (nests := !nests + 1; left_parenthesis := false)
                  end
              | ')' ->
                  begin
                    if !asterisk then (nests := !nests - 1; asterisk := false);
                    if !left_parenthesis then left_parenthesis := false
                  end
              | _ ->
                begin
                  if c = '\n' then (line := !line + 1; chr := 0) else chr := !chr + 1;
                  if !asterisk then asterisk := false;
                  if !left_parenthesis then left_parenthesis := false
                end
            end;
            if !nests = 0 then raise @@ Out_of_loop (index, { line = !line; chr = !chr });
        done;
        raise @@ Syntax_error { line = !line; chr = !chr }
      with
        Out_of_loop (i, location) -> (i, location)
      in
      [{ ast = (); loc; rest = String.sub src (idx + 1) (String.length src - idx - 1) }])

let spaces = drop (some @@ ((drop @@ oneOf " \t\n") <|> comment))

let spaces_opt = drop (many @@ ((drop @@ oneOf " \t\n") <|> comment))

let letter = satisfy (fun (_, c) ->
  let code = Char.code c in
    (65 <= code && code <= 90) || (97 <= code && code <= 122))

let identifier =
  (fun (loc, c) results -> (loc, Base.String.of_char_list (c :: List.map snd results)))
  <$> letter
  <*> (many (letter <|> digit_char))

let loc_of_expr_ast = function
  | IntLiteral (loc, _) -> loc
  | Ident (loc, _) -> loc
  | Minus (loc, _) -> loc
  | Add (loc, _, _) -> loc
  | Sub (loc, _, _) -> loc
  | Mul (loc, _, _) -> loc
  | Div (loc, _, _) -> loc
  | Eq (loc, _, _) -> loc
  | Ne (loc, _, _) -> loc
  | Less (loc, _, _) -> loc
  | LessE (loc, _, _) -> loc
  | Greater (loc, _, _) -> loc
  | GreaterE (loc, _, _) -> loc
  | And (loc, _, _) -> loc
  | Or (loc, _, _) -> loc
  | IfElse (loc, _, _, _) -> loc
  | Let (loc, _, _, _) -> loc
  | Funcall (loc, _, _) -> loc

let addop =
  let
    add = char '+' >> return (fun lhs rhs -> Add (loc_of_expr_ast lhs, lhs, rhs)) and
    sub = char '-' >> return (fun lhs rhs -> Sub (loc_of_expr_ast lhs, lhs, rhs))
  in
    add <|> sub

let mulop =
  let
    mul = char '*' >> return (fun lhs rhs -> Mul (loc_of_expr_ast lhs, lhs, rhs)) and
    div = char '/' >> return (fun lhs rhs -> Div (loc_of_expr_ast lhs, lhs, rhs))
  in
    mul <|> div

let cmpop =
  (token "==" >> return (fun lhs rhs -> Eq (loc_of_expr_ast lhs, lhs, rhs)))
  <|> (token "!=" >> return (fun lhs rhs -> Ne (loc_of_expr_ast lhs, lhs, rhs)))
  <|> (token "<=" >> return (fun lhs rhs -> LessE (loc_of_expr_ast lhs, lhs, rhs)))
  <|> (token "<" >> return (fun lhs rhs -> Less (loc_of_expr_ast lhs, lhs, rhs)))
  <|> (token ">=" >> return (fun lhs rhs -> GreaterE (loc_of_expr_ast lhs, lhs, rhs)))
  <|> (token ">" >> return (fun lhs rhs -> Greater (loc_of_expr_ast lhs, lhs, rhs)))

let andop =
  token "&&"
  >> return (fun lhs rhs -> And (loc_of_expr_ast lhs, lhs, rhs))

let orop =
  token "||"
  >> return (fun lhs rhs -> Or (loc_of_expr_ast lhs, lhs, rhs))

let chain p op =
  let rec rest ast =
    (spaces_opt >> ((fun f b -> f ast b) <$> op <*> (spaces_opt >> p) >>= rest))
    <|> return ast
  in
  p
  >>= rest
  >>= (fun ast -> spaces_opt >> return ast)

let rec factor () =
  let if_expr = Parser (function (loc, _) as result ->
    result
    |> parse (
      token "if"
      >> spaces
      >> logical_expr_or ()
      >>= (fun cond ->
        token "then"
        >> spaces
        >> logical_expr_or ()
        >>= (fun then_clause ->
          token "else"
          >> spaces
          >> logical_expr_or ()
          >>= (fun else_clause ->
            return @@ IfElse (loc, cond, then_clause, else_clause))))))
  in
  let let_expr = Parser (function (loc, _) as input ->
    input
    |> parse (
      token "let"
      >> spaces
      >> identifier
      >>= (fun ident ->
        spaces_opt
        >> char '='
        >> spaces_opt
        >> logical_expr_or ()
        >>= (fun bound_expr ->
          token "in"
          >> spaces
          >> logical_expr_or ()
          >>= (fun expr ->
            return @@ Let (loc, ident, bound_expr, expr))))))
  in
  let funcall =
    Parser (function (loc, _) as input ->
      input
      |> parse (
        identifier
        >>= (fun (_, ident) ->
          char '('
          >> spaces_opt
          >> option [] (List.cons
            <$> logical_expr_or ()
            <*> many (char ',' >> spaces_opt >> logical_expr_or ()))
          >>= (fun asts ->
            char ')'
            >> spaces_opt
            >> return @@ Funcall (loc, ident, asts)))))
  in
  nat
  <|> funcall
  <|> Parser (fun input -> input |> parse (char '(' >> logical_expr_or () >>= (fun c -> char ')' >> return c)))
  <|> if_expr
  <|> let_expr
  <|> (identifier >>= (fun (loc, name) -> spaces_opt >> return @@ Ident (loc, name)))

and term () = chain (factor ()) mulop

and arithmetic_expr () =
  unary <*> chain (term ()) addop

and comparison_expr () =
  chain (arithmetic_expr ()) cmpop

and logical_expr_and () =
  chain (comparison_expr ()) andop

and logical_expr_or () =
  chain (logical_expr_and ()) orop

let func_def = Parser (function (loc, _) as input ->
  input
  |> parse (
    option false (token "pub" >> spaces >> return true)
    >>= (fun pub ->
      token "fn"
      >> spaces
      >> identifier
      >>= (fun name ->
        spaces_opt
        >> char '('
        >> spaces_opt
        >> option [] (List.cons
          <$> identifier
          <*> many (
            char ','
            >> spaces_opt
            >> identifier
            >>= (fun ident ->  spaces_opt >> return ident)))
        >>= (fun args ->
          char ')'
          >> spaces_opt
          >> char '{'
          >> spaces_opt
          >> logical_expr_or ()
          >>= (fun body ->
            char '}'
            >> spaces_opt
            >> return @@ FuncDef (loc, pub, name, args, body)))))))

let program src =
  let parser =
    (spaces_opt
    >> func_def
    >>= (fun head ->
      many func_def
        >>= (fun tail ->
          return @@ head :: tail)))
    <|> (spaces_opt >> return [])
  in
  begin
    let result = parse parser (bof, src) in
    result
    |> List.iter (function
      | { ast = _; loc; rest } when rest <> "" -> raise @@ Syntax_error loc
      | _ -> ());
    (List.hd result).ast
  end
