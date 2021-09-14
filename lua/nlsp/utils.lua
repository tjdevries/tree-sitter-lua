local utils = {}

local NIL = vim.NIL

--@private
--- Returns its argument, but converts `vim.NIL` to Lua `nil`.
--@param v (any) Argument
--@returns (any)
function utils.convert_NIL(v)
  if v == NIL then
    return nil
  end
  return v
end

--@private
--- Checks whether a given path exists and is a directory.
--@param filename (string) path to check
--@returns (bool)
function utils.is_dir(filename)
  local stat = vim.loop.fs_stat(filename)
  return stat and stat.type == "directory" or false
end

return utils
