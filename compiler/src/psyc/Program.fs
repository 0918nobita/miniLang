open System
open System.Collections.Generic
// open ParserCombinator

(*
type ExprAST =
    | IntLiteral of loc : Location * value : int
    | Ident of loc : Location * name : string
    | Minus of loc : Location * expr : ExprAST
    | InfixOp of loc : Location * name : string
    | Apply of loc : Location * func : ExprAST * param : ExprAST

let zero = char '0'

let nonZeroDigit = oneOf "123456789"

let digit = zero <|> nonZeroDigit

let unary =
    let plus = char '+' |. succeed id
    let minus =
        char '-'
        |= (fun (loc, _) ->
            succeed (fun ast -> Minus (loc, ast)))
    plus <|> minus <|> succeed id

let nat =
    let digitVal = fmap (fun (loc, c) -> (loc, int c - int '0')) digit
    let toNum x acc = x * 10 + acc
    some digitVal
    |= (fun result ->
        succeed <| IntLiteral (fst (List.head result), List.fold toNum 0 (List.map snd result)))

let letter =
    oneOf "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

let identifier =
    letter
    |= (fun (loc, head) ->
        many (letter <|> digit)
        |= (fun cs ->
            let name =
                head :: (List.map snd cs)
                |> List.toArray
                |> String
            succeed <| Ident (loc, name)))

let factor = (unary <*> nat) <|> identifier

let infixOperator =
    some (oneOf "!$%&*+-./:<=>?@^|~")
    |= (fun cs ->
        let name =
            List.map snd cs
            |> List.toArray
            |> String
        succeed <| InfixOp (fst (List.head cs), name))
*)

let opPriority =
    [("+", 2); ("-", 2); ("*", 3); ("/", 3)]

let isOperator token =
    opPriority
    |> List.exists (fun item -> fst item = token)

let getOpPriority token =
    opPriority
    |> List.find (fun item -> fst item = token)
    |> snd

type Tree =
    | IntLiteral of value : int
    | InfixApply of op : string * lhs : Tree * rhs : Tree

let parseExpr (expr : string) =
    let ops = Stack<string>() // 演算子のスタック
    let terms = Stack<Tree>() // 項のスタック
    let tokens = expr.Split([|' '|])
    tokens
    |> Array.iter (function
        | token when isOperator token ->
            let mutable breakNow = false
            while (not breakNow) && ops.Count > 0 do
                let lastOp = ops.Pop()
                if isOperator lastOp && getOpPriority token <= getOpPriority lastOp
                    then
                        let right = terms.Pop()
                        let left = terms.Pop()
                        terms.Push(InfixApply (lastOp, left, right))
                    else
                        ops.Push(lastOp)
                        breakNow <- true
            ops.Push(token)
        | token when fst <| Int32.TryParse(token) ->
            terms.Push(IntLiteral <| Int32.Parse(token))
        | "(" ->
            ops.Push("(")
        | ")" ->
            let mutable breakNow = false
            while (not breakNow) && ops.Count > 0 do
                let op = ops.Pop()
                if op = "("
                    then
                        breakNow <- true
                    else
                        let right = terms.Pop()
                        let left = terms.Pop()
                        terms.Push(InfixApply (op, left, right))
        | _ -> failwith "Invalid expr")
    while ops.Count > 0 do
        let op = ops.Pop()
        if isOperator op
            then
                let right = terms.Pop()
                let left = terms.Pop()
                terms.Push(InfixApply (op, left, right))
    terms.Pop()

[<EntryPoint>]
let main argv =
    if Array.isEmpty argv
        then -1
        else
            printfn "%A" <| parseExpr argv.[0]
            0
