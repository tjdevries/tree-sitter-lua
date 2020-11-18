-- TODO: Need to make a way to write a header section
-- TODO: Need a way to document non-function values
-- TODO: Need to parse return { x = y, z = foo }, etc. and transform
-- TODO: Also need to add boilerplate stuff like modeline, etc.

local M = {}

--- Example function
---@param a number: This is a number
---@param b number: Also a number
M.example = function(a, b)
  return a + b
end

--- Cool function, not as cool as rocker tho
---@param longer_name string: This is a string
---@return nil
M.cool = function(longer_name, ...)
  print(longer_name, ...)
end

--- Cooler function, with no params
---@eval { ["return"] = 'Docs generated at: ' .. os.date() }
---@return nil
function M:even_cooler()
end

M.not_documented = function()
end

-- TODO: Figure out how to exclude the not exported stuff.
--local NotExported = {}

local NotExported = {}

--- Should not get exported
---@param wow string: Yup
NotExported.not_exported = function(wow)
  print(wow)
end

return M
