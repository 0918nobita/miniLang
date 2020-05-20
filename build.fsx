#load "./.fake/build.fsx/intellisense.fsx"

open Fake.Core
open Fake.Core.TargetOperators
open Fake.DotNet
open Fake.IO
open Fake.IO.Globbing.Operators

Target.create "Clean" (fun _ -> !! "src/**/bin" ++ "src/**/obj" |> Shell.cleanDirs)

// Debug build
Target.create "Debug" (fun _ ->
    !! "src/**/*.fsproj"
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

"Clean" ==> "Debug"

"Clean" ==> "Release"

Target.runOrDefault "Debug"
