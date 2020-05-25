(module
  (type $return_i32 (func (result i32)))

  (table (export "tbl") 4 anyfunc)
  (elem (i32.const 0) $1 $2 $3)

  (func $1 (result i32)
    i32.const 111)

  (func $2 (result i32)
    i32.const 222)

  (func $3 (result i32)
    i32.const 333)

  (func (export "call_indirect") (param $i i32) (result i32)
    get_local $i
    call_indirect (type $return_i32))

  (func (export "add") (param $x i32) (param $y i32) (result i32)
    get_local $x
    get_local $y
    i32.add))
