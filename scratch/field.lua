local x = {}

--- This function has documentation
---@param t table: Some table
---@field name string: name
function x.hello(t)
  return t.name
end

--- Whats the node of this snippet
x.bye = function()
  return 5
end

return x
