type MaybeBuilder () =
    member this.Bind (x, f) =
        printfn "Bind: %A" x
        match x with
            | Some(x) -> f x
            | _ -> None
    member this.Delay (f) =
        printfn "Delay"
        f ()
    member this.Return (x) =
        printfn "Return: %A" x
        Some x

[<EntryPoint>]
let main _ =
    let maybe = MaybeBuilder()
    maybe {
        let x = 11
        let! y = Some 22
        let! z = Some 33
        return x + y + z
    }
    |> printfn "%A"
    0
