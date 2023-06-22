vim.opt.rtp:append { ".", "../plenary.nvim" }

vim.cmd [[runtime! plugin/plenary.vim]]
vim.cmd [[runtime! plugin/ts_lua.lua]]

-- Set the parser to this lua parser
vim.treesitter.language.add("lua", {
  path = "./parser/lua.so",
})
