open Wasm
open Wast

let push =
  Func
    { signature = { params = 1; results = 0}
    ; locals = 0
    ; code = bin_of_wasm_insts
      [ I32_store ([Get_global 0], [Get_local 0])
      ; Set_global (0, [I32_sub ([Get_global 0], [I32_const 4])])
      ]
    }

let pop_func =
  Func
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code = bin_of_wasm_insts
      [ Set_global (0, [I32_add ([Get_global 0], [I32_const 4])])
      ; I32_load [Get_global 0]
      ]
    }

let top =
  Func
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code = bin_of_wasm_insts [ I32_load [I32_add ([Get_global 0], [I32_const 4])] ]
    }
