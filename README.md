# tree-sitter-(n)lua

Tree sitter grammar for Lua built to be used inside of Neovim.

Goal: Make a super great Lua grammar and tailor it to usage for Neovim.

# Thoughts on LSP:

OK, so here's what I'm thinking:

1. We have tree sitter for Lua (that we wrote)
2. Can use tree sitter + queries to get information about one file
    - This is like, what a variable is in the file, where it's defined, references, etc.
3. We can use "programming" to link up multiple files w/ our tree sitter info
    - Use package.path, package.searchers, etc. to find where requires lead to.
4. Now we have "project" level knowledge.
5. Can give smarts based on those things.

ALSO!

We can cheat :) :) :)

Let's say we run our LSP in another neovim instance (just `nvim --headless -c 'some stuff'`)
...
OK

this means we can ask `vim` about itself (and other globals, and your package.path, etc.)


Part 2 of cheating:

we can re-use vim.lsp in our implementation

## Status

- [ ] Grammar
    - [ ]

