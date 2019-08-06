open Binary

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

let bin_of_return_type = function
  | I32 -> 127
  | Void -> 64

let rec bin_of_wasm_insts insts =
  Base.List.concat_map
    insts
    ~f:(function
      | I32_const n -> 65 :: leb128_of_int n
      | I32_add (lhs, rhs) ->
          bin_of_wasm_insts lhs @
          bin_of_wasm_insts rhs @
          [106]
      | I32_sub (lhs, rhs) ->
          bin_of_wasm_insts lhs @
          bin_of_wasm_insts rhs @
          [107]
      | I32_mul -> [108]
      | I32_div_s -> [109]
      | I32_eq (lhs, rhs) ->
          bin_of_wasm_insts lhs @
          bin_of_wasm_insts rhs @
          [70]
      | I32_ne (lhs, rhs) ->
          bin_of_wasm_insts lhs @
          bin_of_wasm_insts rhs @
          [71]
      | I32_gt (lhs, rhs) ->
          bin_of_wasm_insts lhs @ bin_of_wasm_insts rhs @ [74]
      | I32_ge -> [78]
      | I32_lt -> [72]
      | I32_le -> [76]
      | I32_eqz -> [69]
      | If { ret_type; cond; then_ } ->
          bin_of_wasm_insts cond @
          [4; bin_of_return_type ret_type] @
          bin_of_wasm_insts (then_ @ [End])
      | If_else { ret_type; cond; then_; else_ } ->
          bin_of_wasm_insts cond @
          [4; bin_of_return_type ret_type] @
          bin_of_wasm_insts then_ @
          bin_of_wasm_insts (Else :: else_ @ [End])
      | Else -> [5]
      | Block ret_type -> [2; bin_of_return_type ret_type]
      | Loop ret_type -> [3; bin_of_return_type ret_type]
      | Br depth -> 12 :: leb128_of_int depth
      | Br_if (depth, cond) -> bin_of_wasm_insts cond @ 13 :: leb128_of_int depth
      | End -> [11]
      | Call index -> 16 :: leb128_of_int index
      | Get_global index -> 35 :: leb128_of_int index
      | Set_global (index, value) -> bin_of_wasm_insts value @ 36 :: leb128_of_int index
      | Get_local index -> 32 :: leb128_of_int index
      | Set_local (index, value) -> bin_of_wasm_insts value @ 33 :: leb128_of_int index
      | I32_store (addr, value) ->
          bin_of_wasm_insts addr @
          bin_of_wasm_insts value @
          [54; 2 (* alignment *); 0 (* store offset *)]
      | I32_load addr -> bin_of_wasm_insts addr @ [40; 2 (* alignment *); 0 (* load offset *)]
      | Return -> [15])
