(module
  (func (export "add") (param i64) (result f64)
    (f64.reinterpret/i64 (get_local 0))))
