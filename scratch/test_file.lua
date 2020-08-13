local M = {}

--- Example of my_func
---@param y string: Y description
M.my_func = function(y)
end

--- This is a description of the function
---@param x table: X description
---@return nil
function M.other_func(x)
  print(x)
end

return M
