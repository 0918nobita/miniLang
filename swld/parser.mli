open Parser_combinator

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

exception Syntax_error of location

val program : string -> stmt_ast list
