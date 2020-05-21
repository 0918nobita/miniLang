module ParserTest

open Expecto

[<Tests>]
let tests =
    test "simple test"
        { let subject = "Hello, world"
          Expect.equal subject "Hello, world" "The strings should equal"
    }

[<Tests>]
let properties =
    testList "FsCheck"
        [ testProperty "Addition is commutative"
          <| fun a b -> a + b = b + a

          testProperty "reverse list"
          <| fun (xs: int list) ->
              let reversed = List.rev xs
              List.rev reversed = xs ]

[<EntryPoint>]
let main argv = runTestsInAssembly defaultConfig argv
