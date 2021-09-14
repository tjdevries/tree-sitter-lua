local utils = {}

utils.read = function(f)
  local fp = assert(io.open(f))
  local contents = fp:read "*all"
  fp:close()

  return contents
end

return utils
