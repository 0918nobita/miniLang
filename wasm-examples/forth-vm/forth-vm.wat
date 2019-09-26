(module
  (import "env" "mem" (memory 1))
  (import "env" "log" (func $log (param i32)))

  (global $sp (mut i32) (i32.const 63996))
  (global $pc (mut i32) (i32.const 0))

  (func $push (param $val i32)
    (i32.store
      (get_global $sp)
      (get_local $val))
    (set_global $sp
      (i32.sub
        (get_global $sp)
        (i32.const 4))))

  (func $pop (result i32)
    (set_global $sp
      (i32.add
        (get_global $sp)
        (i32.const 4)))
    (i32.load (get_global $sp)))

  (func $init
    (i32.store (i32.const 0) (i32.const 1))   (; i32.const ;)
    (i32.store (i32.const 4) (i32.const 3))   (; 3 ;)
    (i32.store (i32.const 8) (i32.const 1))   (; i32.const ;)
    (i32.store (i32.const 12) (i32.const 4))  (; 4 ;)
    (i32.store (i32.const 16) (i32.const 2))  (; i32.add ;)
    (i32.store (i32.const 20) (i32.const 1))  (; i32.const ;)
    (i32.store (i32.const 24) (i32.const 1))  (; 1 ;)
    (i32.store (i32.const 28) (i32.const 3))  (; i32.sub ;)
    (i32.store (i32.const 32) (i32.const 0))) (; bye ;)

  (func $advance
    (set_global $pc (i32.add (get_global $pc) (i32.const 4))))

  (func $run
    (local $opcode i32)
    (local $operand_1 i32)
    (local $operand_2 i32)
    (loop
      (set_local $opcode (i32.load (get_global $pc)))

      (; bye ;)
      (if (i32.eq (i32.const 0) (get_local $opcode))
        (then return))

      (; i32.const ;)
      (if (i32.eq (get_local $opcode) (i32.const 1))
        (then
          (call $advance)
          (set_local $operand_1 (i32.load (get_global $pc)))
          (call $push (get_local $operand_1))
          (call $advance)
          br 1))

      (; i32.add ;)
      (if (i32.eq (get_local $opcode) (i32.const 2))
        (then
          (set_local $operand_2 (call $pop))
          (set_local $operand_1 (call $pop))
          (call $push (i32.add (get_local $operand_1) (get_local $operand_2)))
          (call $advance)
          br 1))

      (; i32.sub ;)
      (if (i32.eq (get_local $opcode) (i32.const 3))
        (then
          (set_local $operand_2 (call $pop))
          (set_local $operand_1 (call $pop))
          (call $push (i32.sub (get_local $operand_1) (get_local $operand_2)))
          (call $advance)
          br 1))

      unreachable))

  (func (export "main")
    call $init
    call $run
    (call $log (call $pop))))
