(module
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))

  (data (i32.const 0) "Hello, WASI\n")

  (func (export "_start")
    (i32.store (i32.const 12) (i32.const 0))  ;; buffer の先頭アドレス
    (i32.store (i32.const 16) (i32.const 12)) ;; buffer の長さ
    (call $fd_write
      (i32.const 1)   ;; ファイルディスクリプタ (1: stdout)
      (i32.const 12)  ;; iov の先頭アドレス
      (i32.const 1)   ;; iov の個数
      (i32.const 20)) ;; 出力されたバイト数を受け取るポインタ
    drop
  )
)
