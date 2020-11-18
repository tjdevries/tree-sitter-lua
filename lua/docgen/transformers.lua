local get_node_text = require('vim.treesitter.query').get_node_text

local log = require('docgen.log')

local for_each_child = function(node, cb)
  local named_children_count = node:named_child_count()
  for child = 0, named_children_count - 1 do
    local child_node = node:named_child(child)
    cb(child_node)
  end
end


local transformers = {}

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

  accumulator[name] = {
    name = name,
    format = "function",
  }
  call_transformer(accumulator[name], str, documentation_node)
end

transformers.function_statement = transformers._function
transformers.variable_declaration = transformers._function

transformers.emmy_documentation = function(accumulator, str, node)
  accumulator.parameters = {}
  log.trace("Accumulator:", accumulator)

  for_each_child(node, function(child_node)
    call_transformer(accumulator, str, child_node)
  end)
end

transformers.emmy_comment = function(accumulator, str, node)
  -- TODO: Make this not ugly
  -- It should strip out the --- at the begging of the comment
  accumulator.description = vim.trim(get_node_text(node, str))
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
end

transformers.emmy_return = function(accumulator, str, node)
  -- print(get_node_text(node, str))
  if not accumulator['return'] then
    accumulator['return'] = {}
  end

  table.insert(accumulator['return'], get_node_text(node, str))
end

transformers.emmy_eval = function(accumulator, str, node)
  local ok, result = pcall(loadstring('return ' .. get_node_text(node, str)))

  if ok then
    if type(result) == 'table' then
      for k, v in pairs(result) do
        assert(type(k) == 'string', "Not implemented to be nested tables yet.")

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
