build:
	make -C ./compiler
	make -C ./swld MAKE_DEPS=false

test: ./compiler/_build/psyche
	make -C ./test

clean:
	make -C ./binary-utils clean
	make -C ./parser-combinator clean
	make -C ./compiler clean
	make -C ./swld clean
