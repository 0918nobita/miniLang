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

let dashPattern = @"^-([a-zA-Z]+)$"

let doubleDashPattern = @"^--([a-zA-Z]+)$"

let (|Dash|_|) (input: string) =
    let m = Regex.Match(input, dashPattern)
    if m.Success then Some(m.Groups.[1].Value) else None

let (|DoubleDash|_|) (input: string) =
    let m = Regex.Match(input, doubleDashPattern)
    if m.Success then Some(m.Groups.[1].Value) else None

let (|NotOption|_|) (input: string) =
    let m1 = Regex.Match(input, dashPattern)
    let m2 = Regex.Match(input, doubleDashPattern)
    if not m1.Success && not m2.Success then Some() else None

let setOut (options: BuildOptions) (out: string) = { options with Out = out }

let setVerbose (options: BuildOptions) = { options with Verbose = true }

let rec parseBuildCmd (baseOptions: BuildOptions) =
    function
    | [] -> baseOptions

    | (DoubleDash name) :: xs when name = "verbose" -> parseBuildCmd (setVerbose baseOptions) xs
    | (Dash name) :: xs when name = "v" -> parseBuildCmd (setVerbose baseOptions) xs

    | (DoubleDash name) :: (NotOption as out) :: xs when name = "out" -> parseBuildCmd (setOut baseOptions out) xs
    | (Dash name) :: (NotOption as out) :: xs when name = "o" -> parseBuildCmd (setOut baseOptions out) xs

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
