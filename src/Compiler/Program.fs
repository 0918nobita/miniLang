module Program

open Argu
open System

type BuildArgs =
    | [<AltCommandLine("-o")>] Out of string
    | [<AltCommandLine("-v")>] Verbose
    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | Out _ -> "Specify output file"
            | Verbose -> "Print a lot of output to stdout"

type HelpArgs =
    | [<CliPrefix(CliPrefix.None); Hidden>] Build
    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | Build -> ""

type Arguments =
    | [<CliPrefix(CliPrefix.None)>] Build of ParseResults<BuildArgs>
    | [<CliPrefix(CliPrefix.None); Hidden>] Help of ParseResults<HelpArgs>
    interface IArgParserTemplate with
        member this.Usage =
            match this with
            | Build -> "Compile packages and dependencies"
            | Help -> ""

[<EntryPoint>]
let main argv =
    let errorHandler =
        ProcessExiter
            (colorizer =
                function
                | ErrorCode.HelpText -> None
                | _ -> Some ConsoleColor.Red)

    let parser = ArgumentParser.Create<Arguments>(programName = "psy.exe", errorHandler = errorHandler)
    let results = parser.ParseCommandLine argv
    printfn "Results: %A" <| results.GetAllResults()
    0
