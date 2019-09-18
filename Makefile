build:
	make -C ./compiler

test: ./compiler/_build/psyche
	make -C ./test

clean:
	make -C ./binary-utils clean
	make -C ./parser-combinator clean
	make -C ./compiler clean
