module Parser

open FParsec

let identParser: Parser<string, unit> =
    let options =
        IdentifierOptions
            (isAsciiIdStart = (fun c -> isAsciiLetter c || c = '_'),
             isAsciiIdContinue =
                 fun c -> isAsciiLetter c || isDigit c || c = '_' || c = '\'')
    identifier options

let runIdentParser() = printfn "%A" <| run identParser "_abc"
