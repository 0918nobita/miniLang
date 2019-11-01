open ParserCombinator

type MaybeBuilder () =
    member this.Bind (x, f) =
        match x with
            | Some(x) -> f x
            | _ -> None
    member this.Delay (f) = f ()
    member this.Return (x) = Some x

type MParsecBuilder () =
    member this.Bind (p, f) =
        {
            parse = fun input ->
                match parse p input with
                | Some { ast = ast; currentLoc = loc; rest = rest } ->
                    parse (f ast) (loc, rest)
                | None -> None
            error = None
        }
    member this.Return (ast) =
        {
            parse = fun (loc, rest) -> Some { ast = ast; currentLoc = loc; rest = rest }
            error = None
        }

[<EntryPoint>]
let main argv =
    if Array.isEmpty argv then exit(1)

    let maybe = MaybeBuilder()
    maybe {
        let x = 11
        let! y = Some 22
        let! z = Some 33
        return x + y + z
    }
    |> printfn "%A"

    // "ac" または "bc" を受理して、１文字目と "!" を結合した文字列を返すパーサ
    let parser = MParsecBuilder()
    parser {
        let! (_, first) = token "a" <|> token "b"
        do! drop <| token "c"
        return first + "!"
    }
    |> (fun p -> parse p (bof, argv.[0]))
    |> printfn "%A"

    0
