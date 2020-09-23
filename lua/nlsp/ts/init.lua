local api = vim.api

local parsers = require'nvim-treesitter.parsers'
local locals = require'nvim-treesitter.locals'

local M = {}

--[[
interface Location {
  uri: DocumentUri;
  range: Range;
}
--]]
function M.get_node_at_position(position, bufnr)
  if not bufnr then
    bufnr = vim.uri_to_bufnr(position.uri)
  end

  if not parsers.has_parser('lua') then return end
  local root = parsers.get_parser(bufnr):parse():root()

  local start_row = position.line
  local start_col = position.character

  return root:named_descendant_for_range(start_row, start_col, start_row, start_col)
end

function M.get_definition_at_position(position, bufnr)
  local position_node = M.get_node_at_position(position, bufnr)
  local definition_node = locals.find_definition(position_node, bufnr)

  print(vim.inspect(definition_node), definition_node)
  print(definition_node:start())
  print(definition_node:end_())
end

function M.test()
  local location = vim.lsp.util.make_position_params().position

  M.get_definition_at_location(location, 0)
end

--[[
lua RELOAD('nlsp'); require('nlsp.ts').test()
--]]

return M
