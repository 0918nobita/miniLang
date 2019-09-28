# SECD 仮想マシン

| ニーモニック | オペコード | 挙動 |
| ---- | ---- | ---- |
| STOP | 0 | 仮想マシンを終了する |
| LD | 1 | 局所変数の値を push する |
| LDC | 2 | 定数を push する |
| LDF | 3 | クロージャを生成して push する |
| ARGS | 4 | 引数リストを生成して push する |
| APP | 5 | スタックに積まれているクロージャと<br>引数リストを取り出して呼び出す |
| RTN | 6 | 関数呼び出しから戻る |
| SEL | 7 | pop した値を条件として分岐 |
| JOIN | 8 | 条件分岐から合流する |
| DROP | 9 | スタックのトップの値を捨てる |
| ADD | 10 | 足し算 |
| MUL | 11 | 掛け算 |

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

## LDF

``code`` からクロージャを生成して push する

即値 ``code : addr``

```
S:               s => (closure code e) :: s
E:               e => e
C: (ldf code) :: c => c
D:               d => d
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
S: (closure code env) :: vs :: s => []
E:                             e => vs :: env
C:                    (app) :: c => code
D:                             d => [s e c] :: d
```

組み込み関数の場合：

```
S: #prim :: vs :: s => (apply #prim vs) :: s
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
 0 |  3  (LDC)
 1 |  8
 2 |  2  (LDC)
 3 |  2
 4 |  4  (ARGS)
 5 |  1
 6 |  5  (APP)
 7 |  0  (STOP)
 8 |  1  (num params)
 9 |  0  (param 1 "a")
10 |  1  (LD)
11 |  0
12 |  0
13 |  2  (LDC)
14 |  1
15 | 10  (ADD)
16 |  6  (RTN)
```

実行中の S, E, C, D の状態遷移：

```
S [8],      E [],    C  2, D []                         (LDF 8)
S [2; 8],   E [],    C  4, D []                         (LDC 2)
S [[2]; 8], E [],    C  6, D []                         (ARGS 1)
S [],       E [[2]], C 10, D [{s = [], e = [], c = 7}]  (APP)
S [2],      E [[2]], C 13, D [{s = [], e = [], c = 7}]  (LD 0, 0)
S [1; 2],   E [[2]], C 15, D [{s = [], e = [], c = 7}]  (LDC 1)
S [3],      E [[2]], C 16, D [{s = [], e = [], c = 7}]  (ADD)
S [3],      E [],    C  7, D []                         (RTN)
Result: 3
```
