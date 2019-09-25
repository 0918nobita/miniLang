(async () => {
  const mem = new WebAssembly.Memory({ initial: 1 });
  const log = n => console.log(n);
  const importObject = { env: { mem, log } };
  const { instance } =
    await WebAssembly.instantiateStreaming(
      fetch('./forth-vm.wasm'),
      importObject);
  instance.exports.main();
})();
