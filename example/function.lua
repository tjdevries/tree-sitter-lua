local m = {}

--- We will not generate documentation for this function
local some_func = function()
  return 5
end

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
m.__hidden = function()
  return 5
end

--- The documentation for this function will be generated.
--- The markdown renderer will be used again.<br>
--- With the same set of features
m.actual_func = function()
  return 5
end

return m
