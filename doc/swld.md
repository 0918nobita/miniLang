# SWLD - Segmental WASM Linker

## Segmetal WASM

### Syntax

#### global

```
global sp mut i32
  i32.const 42
endglobal
```

### function

```
function foo(arg1 i32, arg2 i32) i32
endfunction
```

### Instructions

#### i32.const

#### i32.add

#### i32.sub

#### i32.mul

#### i32.div_s

#### get_local

#### set_local

#### get_global

#### set_global

#### block

#### end

#### return

#### loop

#### br

#### br_if

#### br_table

#### i32.load

#### i32.store
