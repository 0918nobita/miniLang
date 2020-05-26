const { instance } =
    await WebAssembly.instantiate(Deno.readFileSync('table.wasm'), {});

const call_indirect: (i: number) => number = instance.exports.call_indirect;
const tbl: WebAssembly.Table = instance.exports.tbl;
const add: (x: number, y: number) => number = instance.exports.add;

console.log(call_indirect(0)); // => 111
console.log(call_indirect(1)); // => 222
console.log(call_indirect(2)); // => 333
tbl.set(3, add);
console.log(tbl.get(3)(3, 4)); // => 7
