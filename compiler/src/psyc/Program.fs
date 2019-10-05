open Argu
open FSharp.Json

type CLIArguments =
    | Version
with
    interface IArgParserTemplate with
        member s.Usage =
            match s with
            | Version -> "version"

type RecordType = { value: int }

[<EntryPoint>]
let main argv =
    let json = Json.deserialize<RecordType> "{ \"value\": 42 }"
    printfn "%A" json
    try
        let parser = ArgumentParser.Create<CLIArguments> "psyc"
        printfn "%A" <| parser.Parse argv
    with
        | :? ArguParseException as exn ->
            printfn "%s" <| exn.Message
    0
