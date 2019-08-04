open Wasm
open Wast

let free =
  Func
    { signature = { params = 1; results = 0}
    ; locals = 3
    ; code = bin_of_wasm_insts
      [ Set_local (1, [I32_sub ([Get_local 0], [I32_const 8])])
      ; Block Void
        ; Loop Void
          ; Set_local (2, [I32_load [Get_local 2]])
          ; If
            { ret_type = Void
            ; cond = [I32_gt ([Get_local 2], [Get_local 1])]
            ; then_ =
              [ I32_store ([Get_local 3], [Get_local 1])
              ; If_else
                { ret_type = Void
                ; cond =
                  [I32_eq
                    ( [Get_local 2]
                    , [I32_add
                        ( [I32_add (
                            [Get_local 1],
                            [I32_load [I32_add ([Get_local 1], [I32_const 4])]])]
                        , [I32_const 8]
                        )]
                    )
                  ]
                ; then_ =
                  [ I32_store ([Get_local 1], [I32_load [Get_local 2]])
                  ; I32_store
                    ( [I32_add ([Get_local 1], [I32_const 4])]
                    , [I32_add
                        ( [I32_add ([I32_const 8], [I32_load [I32_add ([Get_local 1], [I32_const 4])]])]
                        , [I32_load [I32_add ([Get_local 2], [I32_const 4])]]
                        )]
                    )
                  ]
                ; else_ = [I32_store ([Get_local 1], [Get_local 2])]
                }
              ; Return
              ]
            }
          ; Set_local (3, [Get_local 2])
          ; Br_if (0, [I32_ne ([I32_load [Get_local 2]], [I32_const 0])])
        ; End
        ; I32_store ([Get_local 3], [Get_local 1])
      ; End
      ]
    }
