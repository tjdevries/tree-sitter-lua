local Query = require('vim.treesitter.query')

local call_transformer = require('docgen.transformers')

-- Load up our build parser.
-- TODO: Check if this changes within one session?...
vim.treesitter.require_language("lua", "./build/parser.so", true)

local log = require('docgen.log')

local get_node_text = Query.get_node_text

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

function docgen._get_query_text(query_name)
  return read(string.format('./query/lua/%s.scm', query_name))
end

--- Gather the results of a query
---@param bufnr string|number
---@param tree Parser: Already parseed tree
function docgen.gather_query_results(bufnr, tree, query_string)
  local root = tree:root()

  local query = vim.treesitter.parse_query("lua", query_string)

  local gathered_results = {}
  for _, match in query:iter_matches(root, bufnr, 0, -1) do
    local temp = {}
    for match_id, node in pairs(match) do
      local capture_name = query.captures[match_id]
      local text = get_node_text(node, bufnr)

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

function docgen.get_documentation(contents)
  local query_string = read("./query/lua/documentation.scm")
  local gathered_results = docgen.get_query_results(contents, query_string)
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

function docgen.get_ts_query(query_name)
  return vim.treesitter.parse_query("lua", docgen._get_query_text(query_name))
end

function docgen.get_parser(contents)
  return vim.treesitter.get_string_parser(contents, "lua")
end

function docgen.foreach_node(contents, query_name, cb)
  local parser = docgen.get_parser(contents)
  local query = docgen.get_ts_query(query_name)

  for id, node in query:iter_captures(parser:parse():root(), contents, 0, -1) do
    if docgen.debug then print(id, node:type()) end
    cb(id, node)
  end
end

function docgen.transform_nodes(contents, query_name, toplevel_types)
  local t = {}
  docgen.foreach_node(contents, query_name, function(id, node)
    if toplevel_types[node:type()] then
      local ok, result = pcall(call_transformer, t, contents, node)
      if not ok then
        print("ERROR:", id, node, result)
      end
    end
  end)

  return t
end

function docgen.write(input_file, output_file)
  local contents = read(input_file)

  local query_name = 'documentation'
  local toplevel_types = {
    variable_declaration = true,
    function_statement = true,
  }

  local resulting_nodes = docgen.transform_nodes(contents, query_name, toplevel_types)

  if docgen.debug then print(vim.inspect(resulting_nodes)) end

  -- Clear everything
  local out = io.open(output_file, "w")
  for _, v in pairs(resulting_nodes) do
    local result = docgen.transform_function(v)
    if not result then error("Missing result") end

    out:write(result)
    out:write("\n")
  end

  out:close()
end

function docgen.test()
  local input_file = "./scratch/module_example.lua"
  local output_file = "./scratch/output.txt"

  docgen.write(input_file, output_file)
  vim.cmd [[checktime]]
end

function docgen.transform_function(metadata)
  local help = require('docgen.help')

  return help.format_function_metadata(metadata)
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
