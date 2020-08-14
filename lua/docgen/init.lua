-- Load up our build parser.
-- TODO: Check if this changes within one session?...
vim.treesitter.require_language("lua", "./build/parser.so", true)

local log = require('docgen.log')

local ts_utils = require('nvim-treesitter.ts_utils')
local get_text = function(bufnr, node, single)
  local res = ts_utils.get_node_text(node, bufnr)

  if single then return res[1] else return res end
end

local read = function(f)
  local fp = assert(io.open(f))
  local contents = fp:read("all")
  fp:close()

  return contents
end

local get_parent_from_var = function(name)
  local colon_start = string.find(name, ":", 0, true)
  local dot_start = string.find(name, ".", 0, true)
  local bracket_start = string.find(name, "[", 0, true)

  local parent = nil
  if (not colon_start) and (not dot_start) and (not bracket_start) then
    parent = name
  elseif colon_start then
    parent = string.sub(name, 1, colon_start - 1)
    name = string.sub(name, colon_start + 1)
  elseif dot_start then
    parent = string.sub(name, 1, dot_start - 1)
    name = string.sub(name, dot_start + 1)
  elseif bracket_start then
    parent = string.sub(name, 1, bracket_start - 1)
    name = string.sub(name, bracket_start)
  end

  return parent, name
end

local VAR_NAME_CAPTURE = 'var'
local PARAMETER_NAME_CAPTURE = 'parameter_name'
local PARAMETER_DESC_CAPTURE = 'parameter_description'
local PARAMETER_TYPE_CAPTURE = 'parameter_type'

local docgen = {}

-- TODO: Figure out how you can document this with no actual code for it.
--          This would let you stub things out very nicely.
---@class Parser

--- Gather the results of a query
---@param bufnr string|number
---@param tree Parser: Already parseed tree
function docgen.gather_query_results(bufnr, tree, query_string)
  local root = tree:root()

  local query = vim.treesitter.parse_query("lua", query_string)

  local gathered_results = {}
  for _, match in query:iter_matches(root, bufnr, 0, -1) do
    print("MATCH:", vim.inspect(match))
    local temp = {}
    for match_id, node in pairs(match) do
      local capture_name = query.captures[match_id]
      local text = ts_utils.get_node_text(node, bufnr)[1]

      temp[capture_name] = text
    end

    table.insert(gathered_results, temp)
  end

  return gathered_results
end

function docgen.get_query_results(bufnr, query_string)
  local parser = vim.treesitter.get_parser(bufnr, "lua")

  return docgen.gather_query_results(bufnr, parser:parse(), query_string)
end

function docgen.get_documentation(bufnr)
  local query_string = read("./query/lua/documentation.scm")
  local gathered_results = docgen.get_query_results(bufnr, query_string)
  print("GATHERED: ", vim.inspect(gathered_results))

  local results = {}
  for _, match in ipairs(gathered_results) do
    print("MATCH: ", vim.inspect(match))
    local raw_name = match[VAR_NAME_CAPTURE]
    local paramater_name = match[PARAMETER_NAME_CAPTURE]
    local parameter_description = match[PARAMETER_DESC_CAPTURE]
    local parameter_type = match[PARAMETER_TYPE_CAPTURE]

    local parent, name = get_parent_from_var(raw_name)

    local res
    if parent then
      if results[parent] == nil then
        results[parent] = {}
      end

      if results[parent][name] == nil then
        results[parent][name] = {}
      end

      res = results[parent][name]
    else
      if results[name] == nil then
        results[name] = {}
      end

      res = results[name]
    end

    if res.params == nil then
      res.params = {}
    end

    table.insert(res.params, {
      original_parent = parent,
      name = paramater_name,
      desc = parameter_description,
      type = parameter_type,
    })
  end

  return results
end

docgen.get_exports = function(bufnr)
  local return_string = read("./query/lua/module_returns.scm")
  return docgen.get_query_results(bufnr, return_string)
end

docgen.get_exported_documentation = function(lua_string)
  local documented_items = docgen.get_documentation(lua_string)
  local exported_items = docgen.get_exports(lua_string)

  local transformed_items = {}
  for _, transform in ipairs(exported_items) do
    if documented_items[transform.defined] then
      transformed_items[transform.exported] = documented_items[transform.defined]

      documented_items[transform.defined] = nil
    end
  end

  for k, v in pairs(documented_items) do
    transformed_items[k] = v
  end

  return transformed_items
end


local for_each_child = function(node, cb)
  local named_children_count = node:named_child_count()
  for child = 0, named_children_count - 1 do
    local child_node = node:named_child(child)
    cb(child_node)
  end
end

local transformers = {}

local call_transformer = function(accumulator, bufnr, node)
  if transformers[node:type()] then
    return transformers[node:type()](accumulator, bufnr, node)
  end
end

transformers.variable_declaration = function(accumulator, bufnr, node)
  local documentation_node, name_node

  -- TODO: Get a field API merged upstream for tree sitter.
  for_each_child(node, function(child_node)
    if child_node:type() == "variable_declarator" then
      name_node = child_node
    elseif child_node:type() == "emmy_documentation" then
      documentation_node = child_node
    end
  end)

  assert(documentation_node, "Documentation must exist for this variable")
  assert(name_node, "Variable must have a name")

  local name = ts_utils.get_node_text(name_node, bufnr)[1]

  accumulator[name] = {
    name = name,
    format = "function",
  }
  call_transformer(accumulator[name], bufnr, documentation_node)
end

transformers.emmy_documentation = function(accumulator, bufnr, node)
  accumulator.parameters = {}
  log.trace("Accumulator:", accumulator)

  for_each_child(node, function(child_node)
    call_transformer(accumulator, bufnr, child_node)
  end)
end

transformers.emmy_comment = function(accumulator, bufnr, node)
  -- TODO: Make this not ugly
  -- It should strip out the --- at the begging of the comment
  accumulator.description = vim.trim(table.concat(ts_utils.get_node_text(node, bufnr), "\n"))
end

transformers.emmy_parameter = function(accumulator, bufnr, node)
  local name_node = node:named_child(0)
  assert(name_node, "Parameters must have a name")

  local type_node = node:named_child(1)
  local desc_node = node:named_child(2)

  local name = ts_utils.get_node_text(name_node, bufnr)[1]

  accumulator.parameters[name] = {
    name = name,
    type = get_text(bufnr, type_node, true),
    description = get_text(bufnr, desc_node),
  }
end

transformers.emmy_return = function(accumulator, bufnr, node)
end

function docgen.test()
  -- local bufnr = vim.api.nvim_get_current_buf()
  local bufnr = 33

  local parser = vim.treesitter.get_parser(bufnr, "lua")
  local return_string = read("./query/lua/_test.scm")
  local query = vim.treesitter.parse_query("lua", return_string)

  local t = {}
  for id, node in query:iter_captures(parser:parse():root(), bufnr, 0, -1) do
    if transformers[node:type()] then
      -- TODO: Return and accumulate something...
      call_transformer(t, bufnr, node)
    end
  end

  -- print(vim.inspect(t))
  for _, v in pairs(t) do
    docgen.transform_function(v)
  end
end

local text_width = 78
function docgen.transform_function(metadata)
  local help = require('docgen.help')

  help.format_function_metadata(metadata)
end

--[[
 ["M.example"] = {
     name = "M.example",
    description = "--- Example function",
    parameters = {
      a = {
        description = { "This is a number" },
        name = "a",
        type = "number"
      },
      b = {
        description = { "Also a number" },
        name = "b",
        type = "number"
      }
    }
  }
--]]


vim.cmd [[nnoremap asdf :lua require('plenary.reload').reload_module('docgen'); require('docgen').test()<CR>]]

return docgen
