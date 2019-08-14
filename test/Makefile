build:
	mkdir -p _build
	ocamlopt -o _build/test test.ml
	rm test.cmi test.cmx test.o

test: build
	./_build/test

clean:
	rm -f test tmp result out.wasm
