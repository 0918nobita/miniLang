MLI_FILES := binary.mli parser_combinator.mli parser.mli wast.mli wasm.mli ir.mli

ML_FILES := parser_combinator.ml parser.ml binary.ml wast.ml wasm.ml free.ml ir.ml compiler.ml

build:
	mkdir -p _build
	ocamlopt -c $(MLI_FILES)
	ocamlfind ocamlopt -o _build/psyche -linkpkg -package base -w +a $(ML_FILES)
	rm -f *.cmx *.o

for-toplevel:
	mkdir -p _build
	ocamlc -c $(MLI_FILES)
	ocamlfind ocamlc -o _build/psyche -linkpkg -package base $(ML_FILES)

for-debugging:
	mkdir -p _build
	ocamlc -c $(MLI_FILES)
	ocamlfind ocamlc -g -o _build/psyche -linkpkg -package base $(ML_FILES)
	rm -f *.cmo

clean:
	rm -rf _build
	rm -f *.cmi *.cmo
