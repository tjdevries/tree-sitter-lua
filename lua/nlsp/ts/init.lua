local api = vim.api

local parsers = require('nvim-treesitter.parsers')
local locals = require('nvim-treesitter.locals')

local state = require('nlsp.state')
local nquery = require('nlsp.ts.query')

local M = {}

--[[
interface Location {
  uri: DocumentUri;
  range: Range;
}
--]]
function M.get_node_at_position(uri, position)
  local start_row = position.line
  local start_col = position.character

  local root = M.get_root(uri)
  return root:named_descendant_for_range(start_row, start_col, start_row, start_col)
end

function M.get_root(uri)
  local parser = assert(state.get_ts_parser(uri), "File must be open before getting position")

  if not parsers.has_parser('lua') then return end
  return parser:parse():root()
end


function M.get_definition_at_position(uri, position)
  local text = state.get_text_document_item(uri).text
  local root = M.get_root(uri)
  local query = nquery.get('locals')

  local start_row, _, end_row, _ = root:range()

  for k, v in query:iter_captures(root, text, start_row, end_row + 1) do
    print(k, v, require('vim.treesitter.query').get_node_text(v, text))
  end

  -- vim.treesitter.parse_query({lang}, {query})
  --  Parse {query} as a string. (If the query is in a file, the caller
  --         should read the contents into a string before calling).

  -- query:iter_captures({node}, {bufnr}, {start_row}, {end_row})
  -- local definition_node = locals.find_definition(position_node, text)

  -- print(vim.inspect(definition_node), definition_node)
  -- print(definition_node:start())
  -- print(definition_node:end_())
end

function M.test()
  local location = vim.lsp.util.make_position_params().position

  state.textDocumentItem.open({
    uri = vim.uri_from_bufnr(0),
    text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"),
  })
  M.get_definition_at_position(vim.uri_from_bufnr(0), location)
end

--[[
lua RELOAD('nlsp'); require('nlsp.ts').test()
--]]

return M
