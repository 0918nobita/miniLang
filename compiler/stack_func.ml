open Wasm
open Wast

let sp = 0 (* stack pointer *)

let push =
  Func
    { signature = { params = 1; results = 0}
    ; locals = 0
    ; code =
      let value = 0 in
      bin_of_wasm_insts
        [ I32_store ([Get_global sp], [Get_local value])
        ; Set_global (sp, [I32_sub ([Get_global sp], [I32_const 4])])
        ]
    }

let pop_func =
  Func
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code =
      bin_of_wasm_insts
        [ Set_global (sp, [I32_add ([Get_global sp], [I32_const 4])])
        ; I32_load [Get_global sp]
        ]
    }

let top =
  Func
    { signature = { params = 0; results = 1}
    ; locals = 0
    ; code =
      bin_of_wasm_insts
        [ I32_load [I32_add ([Get_global sp], [I32_const 4])] ]
    }
