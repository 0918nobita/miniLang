open System
open ParserCombinator

let letter =
    oneOf "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

let digit = oneOf "0123456789"

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
                let result = parse identifier (bof, argv.[0])

                match result with
                | Some { ast = ast; currentLoc = loc; rest = rest } ->
                    printfn "Success!"
                    printfn "ast: %A" <| snd ast
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
