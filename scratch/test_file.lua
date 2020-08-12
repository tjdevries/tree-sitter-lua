local M = {}

M.my_func = function()
end

--- This is a description of the function
---@param x table: X description
---@returns nil
function M.other_func(x)
  print(x)
end

return M
