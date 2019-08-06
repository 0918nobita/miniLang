open Parser

type instruction

exception Unbound_value of Parser_combinator.location * string

val wasm_func_list_of_stmts : stmts: stmt_ast list -> Wasm.func list
