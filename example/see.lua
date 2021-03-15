local math = {}

--- Will return the smaller number
---@param a number: first number
---@param b number: second number
---@return number: smaller number
---@see math.max
function math.min(a, b)
  if a < b then
    return a
  end
  return b
end

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
---@return number: bigger number
---@see math.min
function math.max(a, b)
  if a > b then
    return a
  end
  return b
end

return math
