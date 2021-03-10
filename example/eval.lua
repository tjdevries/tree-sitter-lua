local m = {}

--- The documentation for this function will be generated.
--- The markdown renderer will be used again.<br>
--- With the same set of features
---@eval { ['description'] = require('your_module').__format_keys() }
m.actual_func = function()
  return 5
end

local static_values = {
  'a',
  'b',
  'c',
  'd',
}

m.__format_keys = function()
  -- we want to do formatting
  local table = { '<pre>', 'Static Values: ~' }

  for _, v in ipairs(static_values) do
    table.insert(table, '    ' .. v)
  end

  table.insert(table, '</pre>')
  return table
end

return m
