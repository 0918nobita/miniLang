open Wasm
open Wast

let init =
  Func
    { signature = { params = 0; results = 0}
    ; locals = 0
    ; code = bin_of_wasm_insts
      [ I32_store ([I32_const 0], [I32_const 8])
      ; I32_store ([I32_const 4], [I32_const 0])
      ; I32_store ([I32_const 8], [I32_const 0])
      ; I32_store ([I32_const 12], [I32_const 43978])
      ]
    }

let malloc =
  Func
    { signature = { params = 1; results = 1}
    ; locals = 4
    ; code = [2; 64; 3; 64; 32; 1; 40; 2; 0; 33; 1; 32; 1; 65; 4; 106; 40; 2; 0; 32; 0; 107; 33; 4; 32; 4; 65; 0; 74; 4; 64; 32; 1; 32; 1; 65; 4; 106; 40; 2; 0; 106; 32; 0; 65; 8; 106; 107; 33; 3; 65; 4; 32; 3; 106; 32; 0; 54; 2; 0; 32; 1; 65; 4; 106; 32; 1; 65; 4; 106; 40; 2; 0; 32; 0; 65; 8; 106; 107; 54; 2; 0; 32; 3; 65; 8; 106; 15; 11; 32; 4; 69; 4; 64; 2; 64; 3; 64; 32; 2; 40; 2; 0; 33; 2; 32; 2; 40; 2; 0; 32; 1; 70; 4; 64; 32; 2; 32; 1; 40; 2; 0; 54; 2; 0; 32; 1; 15; 11; 32; 2; 40; 2; 0; 65; 0; 71; 13; 0; 11; 0; 11; 11; 32; 1; 40; 2; 0; 65; 0; 71; 13; 0; 11; 11; 0]
    }

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
