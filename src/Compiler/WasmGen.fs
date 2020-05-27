module WasmGen

open System.IO

let generate() =
    let stream = File.Open("out.wasm", FileMode.Create)
    let writer = new BinaryWriter(stream)
    writer.Write(0x6d736100ul)
    writer.Write(1ul)
    writer.Close()
