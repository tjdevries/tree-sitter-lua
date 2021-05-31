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
local call_transformer = function(accumulator, str, node, return_module)
  if transformers[node:type()] then
    return transformers[node:type()](accumulator, str, node, return_module)
  end
end

transformers._function = function(accumulator, str, node, return_module)
  if not return_module then return end

  local name_node = node:field("name")[1]
  local documentation_node = node:field("documentation")[1]

  assert(documentation_node, "Documentation must exist for this variable")
  assert(name_node, "Variable must have a name")

  local name = vim.trim(get_node_text(name_node, str))

  if not accumulator.functions then
    accumulator.functions = {}
  end
  if not accumulator.function_list then
    accumulator.function_list = {}
  end

  if not name:match(return_module .. "[.:].*") then
    return
  end

  -- If we already have the function skip
  -- Can happen now with function_statement and variable_declaration
  -- (but we still need to match both queries)
  if accumulator.functions[name] == nil then
    accumulator.functions[name] = {
      name = name,
      format = "function",
    }
    table.insert(accumulator.function_list, name)
    call_transformer(accumulator.functions[name], str, documentation_node)
  end
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

transformers.documentation_class = function(accumulator, str, node)
  if not accumulator.classes then
    accumulator.classes = {}
  end
  if not accumulator.class_list then
    accumulator.class_list = {}
  end

  local class_node = node:named_child(0)

  local type_node = class_node:named_child(0)
  local parent_or_desc = class_node:named_child(1)
  local desc_node = class_node:named_child(2)

  local class = {}
  local name = get_node_text(type_node, str)
  class.name = name

  if desc_node == nil then
    class.desc = { get_node_text(parent_or_desc, str) }
  else
    class.parent = get_node_text(parent_or_desc, str)
    class.desc = { get_node_text(desc_node, str) }
  end

  class.fields = {}
  class.field_list = {}

  local named_children_count = node:named_child_count()
  for child = 1, named_children_count - 1 do
    transformers.emmy_field(class, str, node:named_child(child))
  end

  accumulator.classes[name] = class
  table.insert(accumulator.class_list, name)
end

transformers.documentation_tag = function(accumulator, str, node)
  accumulator.tag = get_node_text(node, str)
end

transformers.function_statement = transformers._function
transformers.variable_declaration = transformers._function

transformers.emmy_documentation = function(accumulator, str, node)
  accumulator.class = {}

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

  local name = get_node_text(type_node, str)
  accumulator.class.name = name

  if desc_node == nil then
    accumulator.class.desc = { get_node_text(parent_or_desc, str) }
  else
    accumulator.class.parent = get_node_text(parent_or_desc, str)
    accumulator.class.desc = { get_node_text(desc_node, str) }
  end
end

transformers.emmy_field = function(accumulator, str, node)
  local name_node = node:named_child(0)
  assert(name_node, "Field must have a name")

  local types = {}
  local desc
  for i = 1, node:named_child_count() - 1 do
    if node:named_child(i):type() == "emmy_type" then
      table.insert(types, get_node_text(node:named_child(i), str))
    elseif node:named_child(i):type() == "field_description" then
      if desc ~= nil then
        print("[docgen] [Error]: We should not be here")
      else
        desc = get_node_text(node:named_child(i), str)
      end
    else
      print("[docgen] [Error]: We should not be here")
    end
  end

  local name = get_node_text(name_node, str)

  accumulator.fields[name] = {
    name = name,
    type = types,
    description = { desc },
  }

  if not vim.tbl_contains(accumulator.field_list, name) then
    table.insert(accumulator.field_list, name)
  end
end

transformers.emmy_parameter = function(accumulator, str, node)
  local name_node = node:named_child(0)
  assert(name_node, "Parameters must have a name")

  local types = {}
  local desc
  for i = 1, node:named_child_count() - 1 do
    if node:named_child(i):type() == "emmy_type" then
      table.insert(types, get_node_text(node:named_child(i), str))
    elseif node:named_child(i):type() == "parameter_description" then
      if desc ~= nil then
        print("[docgen] [Error]: We should not be here")
      else
        desc = get_node_text(node:named_child(i), str)
      end
    else
      print("[docgen] [Error]: We should not be here")
    end
  end

  local name = get_node_text(name_node, str)

  accumulator.parameters[name] = {
    name = name,
    type = types,
    description = { desc },
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

transformers.emmy_eval = function(accumulator, str, node)
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

transformers.documentation_config = function(accumulator, str, node)
  local ok, result = pcall(loadstring('return ' .. get_node_text(node, str)))

  if ok then
    if type(result) == 'table' then
      if not accumulator then
        accumulator = {}
      end

      accumulator["config"] = result
    end
  else
    print("ERR:", result)
  end
end

return call_transformer
