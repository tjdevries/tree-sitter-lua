if vim.g.ts_lua_skip_queries then
  return
end

vim.treesitter.language.add("lua", {
  path = "./parser/lua.so",
})

local str = debug.getinfo(2, "S").source:sub(2)
for _, file in ipairs(vim.fn.glob(vim.fn.fnamemodify(str, ":h:h") .. "/queries/lua/*", false, true)) do
  vim.treesitter.query.set("lua", vim.fn.fnamemodify(file, ":t:r"), table.concat(vim.fn.readfile(file), "\n"))
end
