module Program

open Microsoft.FSharp.Reflection

type MyRecord =
    { Foo: int
      Bar: string }

[<EntryPoint>]
let main argv =
    let schemaType = typeof<MyRecord>
    let fields = FSharpType.GetRecordFields(schemaType)
    printfn "[Fields]"
    fields |> Seq.iter (fun field -> printfn "  %s: %A" field.Name field.PropertyType)
    0
