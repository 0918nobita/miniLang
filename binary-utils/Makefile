build:
	ocamlopt binary.mli
	ocamlfind ocamlopt -linkpkg -package base -c -w +a binary.ml

for-toplevel:
	ocamlc binary.mli
	ocamlfind ocamlc -linkpkg -package base -c -w +a binary.ml

clean:
	rm -f *.cmi *.cmo *.cmx *.o
