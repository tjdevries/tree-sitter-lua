local M = {}

--- Example function
---@param a number: This is a number
---@param b number: Also a number
M.example = function(a, b)
  return a + b
end

--- Cool function
---@param longer_name string: This is a string
---@return nil
M.cool = function(longer_name, ...)
  print(longer_name, ...)
end

M.not_documented = function()
end

return M
