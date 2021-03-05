local get_node_text = require('vim.treesitter.query').get_node_text

local log = require('docgen.log')

local for_each_child = function(node, cb)
  local named_children_count = node:named_child_count()
  for child = 0, named_children_count - 1 do
    local child_node = node:named_child(child)
    cb(child_node)
  end
end


---@brief [[
--- Transforms generated tree from tree sitter -> metadata nodes that we can use for the project.
--- Structure of a program is: (TODO)
---@brief ]]
---@tag docgen-transformers
local transformers = {}

--- Takes any node and recursively transforms its children into the corresponding metadata required by |docgen|.
local call_transformer = function(accumulator, str, node)
  if transformers[node:type()] then
    return transformers[node:type()](accumulator, str, node)
  end
end

transformers._function = function(accumulator, str, node)
  local name_node = node:field("name")[1]
  local documentation_node = node:field("documentation")[1]

  assert(documentation_node, "Documentation must exist for this variable")
  assert(name_node, "Variable must have a name")

  local name = get_node_text(name_node, str)

  if not accumulator.functions then
    accumulator.functions = {}
  end

  accumulator.functions[name] = {
    name = name,
    format = "function",
  }
  call_transformer(accumulator.functions[name], str, documentation_node)
end

--- Transform briefs into the accumulator.brief
transformers.documentation_brief = function(accumulator, str, node)
  if not accumulator.brief then
    accumulator.brief = {}
  end

  local result = get_node_text(node, str)
  if result:sub(1, 1) == " " then
    result = result:sub(2)
  end

  table.insert(accumulator.brief, result)
end

-- TODO(conni2461): DO a documentation class

transformers.documentation_tag = function(accumulator, str, node)
  accumulator.tag = get_node_text(node, str)
end

transformers.function_statement = transformers._function
transformers.variable_declaration = transformers._function

transformers.emmy_documentation = function(accumulator, str, node)
  accumulator.classes = {}
  accumulator.class_list = {}

  accumulator.fields = {}
  accumulator.field_list = {}

  accumulator.parameters = {}
  accumulator.parameter_list = {}

  log.trace("Accumulator:", accumulator)

  for_each_child(node, function(child_node)
    call_transformer(accumulator, str, child_node)
  end)
end

transformers.emmy_header = function(accumulator, str, node)
  return transformers.emmy_comment(accumulator, str, node)
end

transformers.emmy_comment = function(accumulator, str, node)
  -- TODO: Make this not ugly
  local text = get_node_text(node, str)

  local raw_lines = vim.split(text, "\n")
  if raw_lines[1] == "" then
    table.remove(raw_lines, 1)
  end

  if not accumulator.description then
    accumulator.description = {}
  end

  for _, line in ipairs(raw_lines) do
    local start, finish = line:find("^%s*---")
    if start then
      line = line:sub(finish + 3)
    end

    if line:sub(1, 1) == " " then
      line = line:sub(2)
    end

    table.insert(accumulator.description, line)
  end
end

transformers.emmy_class = function(accumulator, str, node)
  local type_node = node:named_child(0)
  local parent_or_desc = node:named_child(1)
  local desc_node = node:named_child(2)

  local class = {}
  local name = get_node_text(type_node, str)
  class.name = name

  if desc_node == nil then
    class.desc = { get_node_text(parent_or_desc, str) }
  else
    class.parent = get_node_text(parent_or_desc, str)
    class.desc = { get_node_text(desc_node, str) }
  end

  accumulator.classes[name] = class

  if not vim.tbl_contains(accumulator.class_list, name) then
    table.insert(accumulator.class_list, name)
  end
end

transformers.emmy_field = function(accumulator, str, node)
  local name_node = node:named_child(0)
  assert(name_node, "Field must have a name")

  local type_node = node:named_child(1)
  local desc_node = node:named_child(2)

  local name = get_node_text(name_node, str)

  accumulator.fields[name] = {
    name = name,
    type = get_node_text(type_node, str),
    description = {get_node_text(desc_node, str)},
  }

  if not vim.tbl_contains(accumulator.field_list, name) then
    table.insert(accumulator.field_list, name)
  end
end

transformers.emmy_parameter = function(accumulator, str, node)
  local name_node = node:named_child(0)
  assert(name_node, "Parameters must have a name")

  local type_node = node:named_child(1)
  local desc_node = node:named_child(2)

  local name = get_node_text(name_node, str)

  -- TODO: Handle getting the parameter BEFORE we do this.
  accumulator.parameters[name] = {
    name = name,
    type = get_node_text(type_node, str),
    description = {get_node_text(desc_node, str)},
  }

  if not vim.tbl_contains(accumulator.parameter_list, name) then
    table.insert(accumulator.parameter_list, name)
  end
end

local create_emmy_type_function = function(identifier)
  return function(accumulator, str, node)
    if not accumulator[identifier] then
      accumulator[identifier] = {}
    end

    local text = vim.trim(get_node_text(node, str))
    text = text:gsub(string.format('---@%s ', identifier), '')

    table.insert(accumulator[identifier], text)
  end
end

transformers.emmy_return = create_emmy_type_function('return')
transformers.emmy_see = create_emmy_type_function('see')
transformers.emmy_todo = create_emmy_type_function('todo')
transformers.emmy_usage = create_emmy_type_function('usage')
transformers.emmy_varargs = create_emmy_type_function('varargs')

--- transformers.emmy_eval = function(accumulator, str, node)
function transformers.emmy_eval(accumulator, str, node)
  local ok, result = pcall(loadstring('return ' .. get_node_text(node, str)))

  if ok then
    if type(result) == 'table' then
      for k, v in pairs(result) do
        -- assert(type(v) == 'string', "Not implemented to be nested tables yet." .. vim.inspect(accumulator))
        -- local current_accumulator = accumulator
        -- if type(v) == 'table' then
        --   -- curre
        -- end

        if not accumulator[k] then
          accumulator[k] = {}
        end

        table.insert(accumulator[k],  v)
      end
    end
  else
    print("ERR:", result)
  end
end


return call_transformer
