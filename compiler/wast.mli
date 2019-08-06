type return_type =
  | I32
  | Void

type wasm_inst =
  | I32_const of int
  | I32_add of wasm_inst list * wasm_inst list
  | I32_sub of wasm_inst list * wasm_inst list
  | I32_mul
  | I32_div_s
  | I32_eq of wasm_inst list * wasm_inst list
  | I32_ne of wasm_inst list * wasm_inst list
  | I32_gt of wasm_inst list * wasm_inst list
  | I32_ge
  | I32_lt
  | I32_le
  | I32_eqz
  | If of { ret_type: return_type; cond: wasm_inst list; then_: wasm_inst list }
  | If_else of { ret_type: return_type; cond: wasm_inst list; then_: wasm_inst list; else_: wasm_inst list }
  | Else
  | Block of return_type
  | Loop of return_type
  | Br of int
  | Br_if of int * (wasm_inst list)
  | End
  | Call of int
  | Get_global of int
  | Set_global of int * (wasm_inst list)
  | Get_local of int
  | Set_local of int * wasm_inst list
  | I32_store of wasm_inst list * wasm_inst list
  | I32_load of wasm_inst list
  | Return

val bin_of_wasm_insts : wasm_inst list -> int list
