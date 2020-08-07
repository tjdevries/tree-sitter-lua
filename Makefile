generate:
	./node_modules/.bin/tree-sitter generate

test: generate
	nvim --headless -c "luafile ./lua/tests_to_corpus.lua" -c "qa!"
	./node_modules/.bin/tree-sitter test

build_parser: generate
	cc -o ./build/parser.so -I./src src/parser.c -shared -Os -lstdc++ -fPIC

wasm: build_parser
	./node_modules/.bin/tree-sitter build-wasm

web: wasm
	./node_modules/.bin/tree-sitter web-ui
