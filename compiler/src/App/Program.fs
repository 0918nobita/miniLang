open System
open ParserCombinator

type ExprAST =
    | IntLiteral of loc : Location * value : int
    | Minus of loc : Location * expr : ExprAST

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
            succeed (loc, name)))

[<EntryPoint>]
let main argv =
    if Array.isEmpty argv
        then -1
        else
            try
                let result = parse (unary <*> nat) (bof, argv.[0])

                match result with
                | Some { ast = ast; currentLoc = loc; rest = rest } ->
                    printfn "Success!"
                    printfn "ast: %A" <| ast
                    printfn "currentLoc: %s" <| loc.ToString ()
                    printfn "rest: \"%s\"" rest
                    0
                | None ->
                    printfn "Failed..."
                    -1
            with
            | ParserException (loc, f) ->
                f loc
                -1
