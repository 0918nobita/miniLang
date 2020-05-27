module Program

open System.Reflection
open FSharp.CommandLine

let outputOption =
    commandOption {
        names [ "o"; "out" ]
        description "Specify output file"
        takes (format ("%s"))
        suggests (fun _ -> [ CommandSuggestion.Files None ])
    }

type Verbosity =
    | Quiet
    | Normal
    | Full

let verbosityOption =
    commandOption {
        names [ "v"; "verbosity" ]
        description "Display this amount of information in the log"
        takes (regex @"q(uiet)?$" |> asConst Quiet)
        takes (regex @"n(ormal)?$" |> asConst Quiet)
        takes (regex @"f(ull)?$" |> asConst Full)
    }

let mainCmd =
    let version = Assembly.GetExecutingAssembly().GetName().Version
    command {
        name "psyche"
        description (sprintf "the psyche language compiler version %O" version)
        opt files in outputOption |> CommandOption.zeroOrMore
        opt verbosity in verbosityOption
                         |> CommandOption.zeroOrExactlyOne
                         |> CommandOption.whenMissingUse Normal
        do printfn "%A, %A" files verbosity
        return 0
    }

[<EntryPoint>]
let main argv = Command.runAsEntryPoint argv mainCmd
