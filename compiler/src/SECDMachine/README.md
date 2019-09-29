# SECD 仮想マシン

| ニーモニック | オペコード | 挙動 |
| ---- | ---- | ---- |
| STOP | 0 | 仮想マシンを終了する |
| LD | 1 | 局所変数の値を push する |
| LDC | 2 | 定数を push する |
| ARGS | 3 | 引数リストを生成して push する |
| APP | 4 | スタックに積まれているクロージャと<br>引数リストを取り出して呼び出す |
| RTN | 5 | 関数呼び出しから戻る |
| SEL | 6 | pop した値を条件として分岐 |
| JOIN | 7 | 条件分岐から合流する |
| DROP | 8 | スタックのトップの値を捨てる |
| ADD | 9 | 足し算 |
| MUL | 10 | 掛け算 |

## LD

環境の i 番目のフレームの j 番目の要素を push する

即値 ``i : i32, j : i32``

```
S:             s => (get-lvar e i j) :: s
E:             e => e
C: (ld i j) :: c => c
D:             d => d
```

局所変数の位置 ``(i, j)`` はコンパイル時に求める

## LDC

定数 ``n`` を push する

即値 ``n : i32``

```
S:            s => n :: s
E:            e => e
C: (ldc n) :: c => c
D:            d => d
```

## ARGS

``n`` 個の値を pop してリスト化し、push する

即値 ``n : i32``

```
S: v1 :: ... :: vn :: s => (list v1 ... vn) :: s
E:                    e => e
C:        (args n) :: c => c
D:                    d => d
```

## APP

スタックのトップがクロージャの場合：

```
S: vs :: (closure code env) :: s => []
E:                             e => vs :: env
C:                    (app) :: c => code
D:                             d => [s e c] :: d
```

組み込み関数の場合：

```
S: vs :: #prim :: s => (apply #prim vs) :: s
E:                e => e
C:       (app) :: c => c
D:                d => d
```

## RTN

クロージャの呼び出しから復帰する

```
S:          v :: s => v :: s' 
E:               e => e'
C:      (rtn) :: c => c'
D: [s' e' c'] :: d => d
```

## SEL

pop した値が真ならば ``ct`` に、偽ならば ``cf`` に分岐する

即値 ``ct : addr, cf : addr``

```
S:           v :: s => s
E:                e => e
C: (sel ct cf) :: c => (if v then ct else cf)
D:                d => c :: d
```

## JOIN

条件分岐から合流する

```
S:           s => s
E:           e => e
C: (join) :: _ => c
D:      c :: d => d
```

## DROP

```
S:     v :: s => s
E:          e => e
C: (pop) :: c => c
D:          d => d
```

## ADD

```
S: rhs :: lhs :: s => (i32.add lhs rhs) :: s
E:          e => e
C: (add) :: c => c
D:          d => d
```

## MUL

```
S: rhs :: lhs :: s => (i32.mul lhs rhs) :: s
E:               e => e
C:      (mul) :: c => c
D:               d => d
```

## Examples

```
(fun a -> a + 1) 2
```

メモリの内容：

```
; エントリーポイント
 0 |  2  ; LDC
 1 |  8
 2 |  2  ; LDC
 3 |  2
 4 |  3  ; ARGS
 5 |  1
 6 |  4  ; APP
 7 |  0  ; STOP

; クロージャを表現するサブルーチン
; 先頭に環境を指すポインタがある
 8 | 17  ; env addr
 9 |  1  ; LD
10 |  0
11 |  0
12 |  2  ; LDC
13 |  1
14 |  9  ; ADD
15 |  5  ; RTN

; fun a -> a + 1 の持つフレーム F (配列)
16 | 0  ; 呼び出し時に 2 が書き込まれる

; フレーム F を追加した環境 (線形リスト)
17 | 16  ; car
18 |  0  ; cdr
```
