module Program

/// CAM の命令
type Inst =
    /// 整数をスタックに積む
    | Ldi of int
    /// 真偽値をスタックに積む
    | Ldb of bool
    /// 環境で、指定したインデックスに対応する値をコピーしてスタックに積む
    | Access of int
    /// クロージャを生成してスタックに積む
    | Closure of Inst list
    /// 関数適用 (先頭要素: クロージャ, 2番目の要素: 引数)
    | Apply
    /// 関数の呼び出し元に戻る
    | Return
    /// スタック先頭の値を環境の先頭に移す (環境を拡張する)
    | Let
    /// 環境の先頭の値を取り除く
    | EndLet
    /// スタックの先頭要素が true ならば前者を、false ならば後者を実行する
    | Test of Inst list * Inst list
    | Add
    | Eq

open System.Text.RegularExpressions

let parse (src: string) =
    let lines = src.Split('\n')
    lines
    |> Array.iter (fun line ->
        let matches = Regex("^(\w+) (\w+)$").Match(line)
        printfn "Result: %s" (if matches.Success then "success" else "failed")
        printfn "(1) %s" <| matches.Groups.Item(1).Value
        printfn "(2) %s" <| matches.Groups.Item(2).Value)

[<EntryPoint>]
let main argv =
    parse (argv.[0])
    0
