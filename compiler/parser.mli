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

exception Syntax_error of location

val loc_of_expr_ast : expr_ast -> location

val program : string -> stmt_ast list
