local m = {}

---@class passwd @The passwd c struct
---@field pw_name string: username
---@field pw_passwd string: user password
---@field pw_uid number: user id
---@field pw_gid number: groupd id
---@field pw_gecos string: user information
---@field pw_dir string: user home directory
---@field pw_shell string: user default shell

--- Get user by id
---@param id number: user id
---@return passwd: returns a password table
function m.get_user(id)
  return ffi.C.getpwuid(id)
end

return m
