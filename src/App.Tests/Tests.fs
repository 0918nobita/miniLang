open Expecto

let tests =
    testList "A test group" [
        test "test 1" {
            Expect.equal (2 + 2) 4 "2 + 2"
        }

        test "test 2" {
            Expect.isFalse false "false"
        }

        test "test 3" {
            Expect.isLessThan 1 2 "1 < 2"
        }
    ]

[<EntryPoint>]
let main argv =
    runTests defaultConfig tests
