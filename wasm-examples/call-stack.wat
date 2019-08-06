(module
  (memory 1)
  (global $sp (mut i32) (i32.const 63999))
  (func $push (param i32)
    (i32.store
      (get_global $sp)
      (get_local 0))
    (set_global $sp
      (i32.sub
        (get_global $sp)
        (i32.const 4))))
  (func $pop (result i32)
    (set_global $sp
      (i32.add
        (get_global $sp)
        (i32.const 4)))
    (i32.load
      (get_global $sp)))
  (func $main (result i32)
    (call $push (i32.const 100))
    (call $push (i32.const 200))
    (call $pop)
    (call $pop)
    (i32.add)) (; => 300 ;)
  (export "main" (func $main)))
