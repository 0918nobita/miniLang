module Program

open System

[<EntryPoint>]
let main argv =
    let reader = new IO.StreamReader(Console.OpenStandardInput())

    let writer = new IO.StreamWriter(Console.OpenStandardOutput())

    writer.AutoFlush <- true

    while true do
        let str = reader.ReadLine()
        writer.Write(str)
        writer.WriteLine()
    0
