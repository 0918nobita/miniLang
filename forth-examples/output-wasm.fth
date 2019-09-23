s" out.wasm" w/o create-file throw value fd-out

create WASM-HEADER 8 allot
0x00 WASM-HEADER !
0x61 WASM-HEADER 1 + !
0x73 WASM-HEADER 2 + !
0x6D WASM-HEADER 3 + !
0x00 WASM-HEADER 4 + !
0x00 WASM-HEADER 5 + !
0x00 WASM-HEADER 6 + !
0x01 WASM-HEADER 7 + !

WASM-HEADER 8 fd-out write-file throw

fd-out close-file throw
bye
