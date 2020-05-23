module Program

open System
open System.Text.RegularExpressions

type BuildOptions =
    { Verbose: Boolean
      Out: String }

type Command =
    | Build of BuildOptions
    | Version
    | Help

let (|Dash|_|) (input: string) =
    let m = Regex.Match(input, @"^-([a-zA-Z]+)$")
    if m.Success then Some(m.Groups.[1].Value) else None

let (|DoubleDash|_|) (input: string) =
    let m = Regex.Match(input, @"^--([a-zA-Z]+)$")
    if m.Success then Some(m.Groups.[1].Value) else None

let (|NotOption|_|) (input: string) =
    let dash = Regex.Match(input, @"^-([a-zA-Z]+)$")
    let doubleDash = Regex.Match(input, @"^--([a-zA-Z]+)$")
    if not dash.Success && not doubleDash.Success
    then Some()
    else None

let rec parseBuildCmd (baseOption: BuildOptions) =
    function
    | [] -> baseOption

    | (DoubleDash name) :: xs when name = "verbose" -> parseBuildCmd { baseOption with Verbose = true } xs
    | (Dash name) :: xs when name = "v" -> parseBuildCmd { baseOption with Verbose = true } xs

    | (DoubleDash name) :: (NotOption as dir) :: xs when name = "out" ->
        parseBuildCmd { baseOption with Out = dir } xs
    | (Dash name) :: (NotOption as dir) :: xs when name = "o" -> parseBuildCmd { baseOption with Out = dir } xs

    | str :: _ -> failwith ("parse error: " + str)

let defaultBuildOptions: BuildOptions =
    { Verbose = false
      Out = "./out.wasm" }

let rec parseCmd =
    function
    | "build" :: xs -> Build <| parseBuildCmd defaultBuildOptions xs
    | "version" :: _ -> Version
    | "help" :: _ -> Help
    | (DoubleDash x) :: xs ->
        printfn "specified general option: %s" x
        parseCmd xs
    | x :: _ -> failwith (sprintf "Unknown subcommand %s" x)
    | _ -> Help

[<EntryPoint>]
let main argv =
    printfn "%A" <| parseCmd (Array.toList argv)
    0
