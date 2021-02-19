local x = {}

--- This function has documentation
---@param abc string: Docs for abc
---@param def string: Other docs for def
---@param bxy string: Final docs
function x.hello(abc, def, bxy)
  return abc .. def .. bxy
end

return x
