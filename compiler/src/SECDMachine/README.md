# SECD 仮想マシン

## 命令セット

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
| SUB | 10 | 引き算 |
| MUL | 11 | 掛け算 |
| DIV | 12 | 割り算 |

### LD

環境の i 番目のフレームの j 番目の要素を push する

即値 ``i : i32, j : i32``

```
S:             s => (get-lvar e i j) :: s
E:             e => e
C: (ld i j) :: c => c
D:             d => d
```

局所変数の位置 ``(i, j)`` はコンパイル時に求める

### LDC

定数 ``n`` を push する

即値 ``n : i32``

```
S:            s => n :: s
E:            e => e
C: (ldc n) :: c => c
D:            d => d
```

### ARGS

``n`` 個の値を pop してリスト化し、push する

即値 ``n : i32``

```
S: v1 :: ... :: vn :: s => (list vn ... v1) :: s
E:                    e => e
C:        (args n) :: c => c
D:                    d => d
```

### APP

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

### RTN

クロージャの呼び出しから復帰する

```
S:          v :: s => v :: s' 
E:               e => e'
C:      (rtn) :: c => c'
D: [s' e' c'] :: d => d
```

### SEL

pop した値が真ならば ``ct`` に、偽ならば ``cf`` に分岐する

即値 ``ct : addr, cf : addr``

```
S:           v :: s => s
E:                e => e
C: (sel ct cf) :: c => (if v then ct else cf)
D:                d => c :: d
```

### JOIN

条件分岐から合流する

```
S:           s => s
E:           e => e
C: (join) :: _ => c
D:      c :: d => d
```

### DROP

```
S:     v :: s => s
E:          e => e
C: (pop) :: c => c
D:          d => d
```

### ADD

```
S: rhs :: lhs :: s => (i32.add lhs rhs) :: s
E:          e => e
C: (add) :: c => c
D:          d => d
```

### MUL

```
S: rhs :: lhs :: s => (i32.mul lhs rhs) :: s
E:               e => e
C:      (mul) :: c => c
D:               d => d
```

## プログラム例

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

8 を push
c <- c + 2
{ s = [8]; e = nil; c = 2; d = nil; f = 19 }


【LDC 2】

2 を push
c <- c + 2
{ s = [2; 8]; e = nil; c = 4; d = nil; f = 19 }


【ARGS 1】

pop した値 v を一時保存する
{ s = [8]; e = nil; c = 4; d = nil; f = 19 } (v = 2)

配列 args = [v] の領域を確保・書き込み
19 |  2
f <- f + 1
値 v を破棄
配列 args の先頭アドレスを push 
c <- c + 2
{ s = [19; 8]; e = nil; c = 6; d = nil; f = 20 }


【APP】

c <- c + 1
pop した値 args を一時保存する
{ s = [8]; e = nil; c = 7; d = nil; f = 20 } (args = 19)

pop した値 closure を一時保存する
{ s = []; e = nil; c = 7; d = nil; f = 20 } (args = 19, closure = 8)

配列 dump の領域を確保・書き込み
20 |  0  (スタックの要素数)
21 |  0  (env addr)
22 |  7  (program counter)
※ スタックの要素数が 1 以上の場合、要素数に続けて各要素の値を順番に書き込む
f <- f + 3
スタックを空にする
{ s = []; e = nil; c = 7; d = nil; f = 23 } (args = 19, closure = 8)

dump を線形リスト d の先頭に追加
23 | 20  (car)
24 |  0  (cdr)
f <- f + 2
{ s = []; e = nil; c = 7; d = 23; f = 25 } (args = 19, closure = 8)

closure 番地に格納されている値を、
環境のアドレスとして線形リスト e の先頭に追加
25 | 17  (car)
26 |  0  (cdr)
f <- f + 2
{ s = []; e = 25; c = 7; d = 23; f = 27 } (args = 19, closure = 8)

値 args を線形リスト e の先頭に追加
27 | 19  (car)
28 | 25  (cdr)
f <- f + 2
値 args を破棄
{ s = []; e = 27; c = 7; d = 23; f = 29 } (closure = 8)

c <- closure + 1
値 closure を破棄
{ s = []; e = 27; c = 9; d = 23; f = 29 }


【LD 0, 0】

線形リスト e の 0 番目の要素を取得し、値 frame として一時保存する
{ s = []; e = 27; c = 9; d = 23; f = 29 } (frame = 19)

配列 frame の 0 番目の要素を取得し、値 arg1 として一時保存する
値 frame を破棄
{ s = []; e = 27; c = 9; d = 23; f = 29 } (arg1 = 2)

値 arg1 を push する
c <- c + 3
値 arg1 を破棄
{ s = [2]; e = 27; c = 12; d = 23; f = 29 }


【LDC 1】

1 を push する
c <- c + 2
{ s = [1; 2]; e = 27; c = 14; d = 23; f = 29 }


【ADD】

pop した値 rhs を一時保存する
{ s = [2]; e = 27; c = 14; d = 23; f = 29 } (rhs = 1)

pop した値 lhs を一時保存する
{ s = []; e = 27; c = 14; d = 23; f = 29 } (rhs = 1; lhs = 2)

lhs + rhs を push する
c <- c + 1
値 lhs, rhs を破棄
{ s = [3]; e = 27; c = 15; d = 23; f = 29 }


【RTN】

線形リスト d の先頭要素を取り出し、値 dump として一時保存する
pop した値 rv を一時保存する
スタックを空にする
{ s = []; e = 27; c = 15; d = nil; f = 29 } (dump = 20, rv = 3)

let i = 0;
while (i < dump[0]) {
  s.push(dump[i + 1]);
  i++;
}
s.push(rv);
e <- dump[i + 1]
c <- dump[i + 2]
値 dump, rv を破棄
{ s = [3]; e = 0; c = 7; d = nil; f = 29 }


【STOP】
実行結果：[3]
```

## WASM での実装方法

- S: 線形メモリの末端から先頭に向かってスタックを構築する
  - スタックポインタをグローバル変数で表現する
- E, D: 線形リストで実装する
- C, F: グローバル変数で表現する
