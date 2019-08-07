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

#### Constant

| Mnemonic | Immediates | Signature |
| ---- | ---- | ---- |
| `i32.const` | `$value`: varsint32 | `( -- i32)` |

The `i32.const` instruction returns the value of `$value`.

#### Integer Add

| Mnemonic | Signature |
| ---- | ---- |
| `i32.add` | `(i32 i32 -- i32)` |

The `i32.add` instruction returns the two's complement sum of its operands.

#### Integer Subtract

| Mnemonic | Signature |
| ---- | ---- |
| `i32.sub` | `(i32 i32 -- i32)` |

The `i32.sub` instruction returns the two's complement difference of its operands.

#### Integer Multiply

| Mnemonic | Signature |
| ---- | ---- |
| `i32.mul` | `(i32 i32 -- i32)` |

The `i32.mul` instruction returns the low half of the two's complement product of its operands.

#### Integer Divide

| Mnemonic | Signature |
| ---- | ---- |
| `i32.div_s` | `(i32 i32 -- i32)` |

The `i32.div_s` instruction return the signed quotient of its operands, interpreted as signed.

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
