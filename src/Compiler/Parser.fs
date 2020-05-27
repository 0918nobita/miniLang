module Parser

open FParsec

let identParser: Parser<string, unit> =
    IdentifierOptions
        (isAsciiIdStart = (fun c -> isAsciiLetter c || c = '_'),
         isAsciiIdContinue = fun c ->
             isAsciiLetter c || isDigit c || c = '_' || c = '\'') |> identifier

let runIdentParser() = printfn "%A" <| run identParser "_abc"
