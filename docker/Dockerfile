FROM alpine:edge AS builder

RUN apk add --no-cache git gcc g++

RUN mkdir -p ~/.local/share/nvim/site/pack/vendor/start
RUN git clone --depth 1 https://github.com/nvim-lua/plenary.nvim /plenary.nvim
RUN git clone --depth 1 https://github.com/tjdevries/tree-sitter-lua /tree-sitter-lua

WORKDIR /tree-sitter-lua
RUN mkdir -p parser
RUN cc -o ./parser/lua.so -I./src src/parser.c src/scanner.cc -shared -Os -lstdc++ -fPIC

FROM alpine:edge AS app

# I don't thin we work w/ 0.5.1 anymore
# RUN apk add --no-cache neovim

RUN apk add git build-base cmake automake autoconf libtool pkgconf coreutils curl unzip gettext-tiny-dev
RUN git clone --depth 1 https://github.com/neovim/neovim /neovim
WORKDIR /neovim
RUN make -j4
RUN make install


# Copy all needed libraries from the builder
WORKDIR /usr/lib
COPY --from=builder /usr/lib/libgcc_s.so.1 /usr/lib/libstdc++.so.6 ./

WORKDIR /usr/share/nvim/runtime/pack
RUN mkdir -p vendor/start
WORKDIR /usr/share/nvim/runtime/pack/vendor/start
COPY --from=builder /plenary.nvim plenary.nvim
COPY --from=builder /tree-sitter-lua tree-sitter-lua
RUN ln -s /tmp app
WORKDIR /tmp
