const { instance: { exports: { add, call_indirect, tbl } } } =
    await WebAssembly.instantiate(Deno.readFileSync('table.wasm'), {});

console.log(call_indirect(0)); // => 111
console.log(call_indirect(1)); // => 222
console.log(call_indirect(2)); // => 333
tbl.set(3, add);
console.log(tbl.get(3)(3, 4)); // => 7
