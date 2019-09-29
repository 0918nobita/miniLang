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

実行中の S, E, C, D, F レジスタの状態遷移：

```
初期状態
{ s = nil; e = nil; c = 0; d = nil; f = 19 }


【LDC 8】

空き領域から「8 を car 部に保存するコンスセル」の領域を確保・書き込み
19 |  8  (car)
20 |  0  (cdr)
s にはコンスセルのアドレスを格納
f <- f + 2
c <- c + 2
{ s = 19; e = nil; c = 2; d = nil; f = 21 }


【LDC 2】

「2 を car 部に保存するコンスセル」の領域を確保・書き込み
21 |  2  (car)
22 | 19  (cdr)
s には新しいコンスセルのアドレスを格納
f <- f + 2
c <- c + 2
{ s = 21; e = nil; c = 4; d = nil; f = 23 }


【ARGS 1】

s の指す線形リストの先頭要素を捨てて値 v を一時保存する
{ s = 19; e = nil; c = 4; d = nil; f = 23 } (v = 2)

配列 args = [v] の領域を確保・書き込み
23 |  2
値 v を破棄
f <- f + 1
{ s = 19; e = nil; c = 4; d = nil; f = 24 }

「配列 args のポインタを car 部に保存するコンスセル」の領域を確保・書き込み
24 | 23  (car)
25 | 19  (cdr)
s に新しいコンスセルのアドレスを格納
f <- f + 2
c <- c + 2
{ s = 24; e = nil; c = 6; d = nil; f = 26 }


【APP】

c <- c + 1
s の線形リストの先頭要素を取り出し、値 args として一時保存
{ s = 19; e = nil; c = 7; d = nil; f = 26 } (args = 23)

s の線形リストの先頭要素を取り出し、値 closure として一時保存
{ s = nil; e = nil; c = 7; d = nil; f = 26 } (args = 23, closure = 8)

配列 dump = [s, e, c] の領域を確保・書き込み
26 |  0
27 |  0
28 |  7
f <- f + 3
s <- nil
{ s = nil; e = nil; c = 7; d = nil; f = 29 } (args = 23, closure = 8)

dump を線形リスト d の先頭に追加
29 | 26  (car)
30 |  0  (cdr)
f <- f + 2
{ s = nil; e = nil; c = 7; d = 29; f = 31 } (args = 23, closure = 8)

closure 番地に格納されている値を、
環境のアドレスとして線形リスト e の先頭に追加
31 | 17  (car)
32 |  0  (cdr)
f <- f + 2
{ s = nil; e = 31; c = 7; d = 29; f = 33 } (args = 23, closure = 8)

値 args を線形リスト e の先頭に追加
33 | 23  (car)
34 | 26  (cdr)
f <- f + 2
値 args を破棄
{ s = nil; e = 33; c = 7; d = 29; f = 35 } (closure = 8)

c <- closure + 1
値 closure を破棄
{ s = nil; e = 33; c = 9; d = 29; f = 35 }


【LD 0, 0】

線形リスト e の 0 番目の要素を取得し、値 frame として一時保存する
{ s = nil; e = 33; c = 9; d = 29; f = 35 } (frame = 23)

配列 frame の 0 番目の要素を取得し、値 arg1 として一時保存する
値 frame を破棄
{ s = nil; e = 33; c = 9; d = 29; f = 35 } (arg1 = 2)

値 arg1 を線形リスト s の先頭に追加する
35 |  2  (car)
36 |  0  (cdr)
f <- f + 2
c <- c + 3
値 arg1 を破棄
{ s = 35; e = 33; c = 12; d = 29; f = 37 }


【LDC 1】

1 を線形リスト s の先頭に追加する
37 |  1  (car)
38 |  35  (cdr)
f <- f + 2
c <- c + 2
{ s = 37; e = 33; c = 14; d = 29; f = 39 }


【ADD】

線形リスト s の先頭要素を取り出し、値 rhs として一時保存する
{ s = 35; e = 33; c = 14; d = 29; f = 39 } (rhs = 1)

線形リスト s の先頭要素を取り出し、値 lhs として一時保存する
{ s = nil; e = 33; c = 14; d = 29; f = 39 } (rhs = 1; lhs = 2)

lhs + rhs を線形リスト s の先頭に追加する
39 |  3  (car)
40 |  0  (cdr)
f <- f + 2
c <- 1
値 lhs, rhs を破棄
{ s = 39; e = 33; c = 15; d = 29; f = 41 }


【RTN】

線形リスト d の先頭要素を取り出し、値 dump として一時保存する
線形リスト s の先頭のコンスセルの cdr 部に、dump[0] を書き込む
39 |  3  (car)
40 |  0  (cdr)
{ s = 39; e = 33; c = 15; d = nil; f = 41 } (dump = 26)

e <- dump[1]
c <- dump[2]
値 dump を破棄
{ s = 39; e = 0; c = 7; d = nil; f = 41 }


【STOP】
実行結果：線形リスト S = [3]
```
