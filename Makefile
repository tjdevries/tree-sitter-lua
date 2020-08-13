generate:
	tree-sitter-cli generate

test: generate
	nvim --headless -c "luafile ./lua/tests_to_corpus.lua" -c "qa!"
	tree-sitter-cli test

build_parser: generate
	cc -o ./build/parser.so -I./src src/parser.c -shared -Os -lstdc++ -fPIC

wasm: build_parser
	tree-sitter-cli build-wasm

web: wasm
	tree-sitter-cli web-ui
