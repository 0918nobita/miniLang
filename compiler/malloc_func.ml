open Wasm
open Wast

let init =
  Func
    { signature = { params = 0; results = 0}
    ; locals = 0
    ; code =
      bin_of_wasm_insts
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
    ; code =
      let ptr = 0 in
      let target = 1 in
      let current = 2 in
      let previous = 3 in
      bin_of_wasm_insts
        [ Set_local (target, [I32_sub ([Get_local ptr], [I32_const 8])])
        ; Block Void
          ; Loop Void
            ; Set_local (current, [I32_load [Get_local current]])
            ; If
              { ret_type = Void
              ; cond = [I32_gt ([Get_local current], [Get_local target])]
              ; then_ =
                [ I32_store ([Get_local previous], [Get_local target])
                ; If_else
                  { ret_type = Void
                  ; cond =
                    [I32_eq
                      ( [Get_local current]
                      , [I32_add
                          ( [I32_add (
                              [Get_local target],
                              [I32_load [I32_add ([Get_local target], [I32_const 4])]])]
                          , [I32_const 8]
                          )]
                      )
                    ]
                  ; then_ =
                    [ I32_store ([Get_local target], [I32_load [Get_local current]])
                    ; I32_store
                      ( [I32_add ([Get_local target], [I32_const 4])]
                      , [I32_add
                          ( [I32_add ([I32_const 8], [I32_load [I32_add ([Get_local target], [I32_const 4])]])]
                          , [I32_load [I32_add ([Get_local current], [I32_const 4])]]
                          )]
                      )
                    ]
                  ; else_ = [I32_store ([Get_local target], [Get_local current])]
                  }
                ; Return
                ]
              }
            ; Set_local (previous, [Get_local current])
            ; Br_if (0, [I32_ne ([I32_load [Get_local current]], [I32_const 0])])
          ; End
          ; I32_store ([Get_local previous], [Get_local target])
        ; End
        ]
      }
