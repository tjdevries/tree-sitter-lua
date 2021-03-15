local math = {}

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
math.max = function(a, b)
  if a > b then
    return a
  end
  return b
end

return math
