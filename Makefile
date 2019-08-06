build:
	make -C ./compiler
	make -C ./swld

test:
	make -C ./test-suite test

clean:
	make -C ./binary-utils clean
	make -C ./parser-combinator clean
	make -C ./compiler clean
	make -C ./swld clean
