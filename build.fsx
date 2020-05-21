#load "./.fake/build.fsx/intellisense.fsx"

open Fake.Core
open Fake.Core.TargetOperators
open Fake.DotNet
open Fake.DotNet.Testing
open Fake.IO
open Fake.IO.Globbing.Operators

Target.create "Clean" (fun _ -> !! "src/**/bin" ++ "src/**/obj" |> Shell.cleanDirs)

// Debug build
Target.create "Debug" (fun _ ->
    !! "src/**/*.fsproj"
    ++ "tests/**/*.fsproj"
    |> Seq.iter
        (DotNet.build (fun options ->
            { options with
                  Configuration = DotNet.Debug })))

// Release build
Target.create "Release" (fun _ ->
    !! "src/**/*.fsproj"
    |> Seq.iter
        (DotNet.build (fun options ->
            { options with
                  Configuration = DotNet.Release })))

let dotnet cmd arg = DotNet.exec id cmd arg |> ignore

Target.create "Format" (fun _ ->
    dotnet "fantomas" "--recurse ./src"
    dotnet "fantomas" "--recurse ./tests")

let testProjects = [ "ParserTest" ]

Target.create "Test" (fun _ ->
    [ for x in testProjects -> sprintf "tests/%s/bin/Debug/**/%s.dll" x x ]
    |> function
    | [] -> printfn "There's no test project"
    | x :: xs -> Seq.fold (++) (!!x) xs |> Expecto.run id)

"Clean" ==> "Debug" ==> "Test"

"Clean" ==> "Release"

Target.runOrDefault "Debug"
