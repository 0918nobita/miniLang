open Binary

type return_type =
  | I32
  | Void

type wasm_inst =
  | I32_const of int
  | I32_add
  | I32_sub
  | I32_mul
  | I32_div_s
  | I32_eq
  | I32_ne
  | I32_gt
  | I32_ge
  | I32_lt
  | I32_le
  | I32_eqz
  | If of return_type
  | Else
  | Block of return_type
  | Loop of return_type
  | Br of int
  | Br_if of int
  | End
  | Call of int
  | Get_global of int
  | Set_global of int
  | Get_local of int
  | Set_local of int
  | I32_store
  | I32_load
  | Return

let bin_of_return_type = function
  | I32 -> 127
  | Void -> 64

let bin_of_wasm_insts insts =
  Base.List.concat_map
    insts
    ~f:(function
      | I32_const n -> 65 :: leb128_of_int n
      | I32_add -> [106]
      | I32_sub -> [107]
      | I32_mul -> [108]
      | I32_div_s -> [109]
      | I32_eq -> [70]
      | I32_ne -> [71]
      | I32_gt -> [74]
      | I32_ge -> [78]
      | I32_lt -> [72]
      | I32_le -> [76]
      | I32_eqz -> [69]
      | If ret_type -> [4; bin_of_return_type ret_type]
      | Else -> [5]
      | Block ret_type -> [2; bin_of_return_type ret_type]
      | Loop ret_type -> [3; bin_of_return_type ret_type]
      | Br depth -> 12 :: leb128_of_int depth
      | Br_if depth -> 13 :: leb128_of_int depth
      | End -> [11]
      | Call index -> 16 :: leb128_of_int index
      | Get_global index -> 35 :: leb128_of_int index
      | Set_global index -> 36 :: leb128_of_int index
      | Get_local index -> 32 :: leb128_of_int index
      | Set_local index -> 33 :: leb128_of_int index
      | I32_store -> [54; 2 (* alignment *); 0 (* store offset *)]
      | I32_load -> [40; 2 (* alignment *); 0 (* load offset *)]
      | Return -> [15])
