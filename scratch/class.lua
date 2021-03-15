local TestJob = {}
TestJob.__index = TestJob

---@class TestArray @Numeric table
---@field len int: size

---@class TestMap @Map-like table

--- Some docs for that class
---
---@class TestJob: Job @this is some documentation
---@field cmd string: external command
---@field args table: arguments for command
function TestJob:new(o)
  local obj = o or {}
  return setmetatable(obj, self)
end

--- Start a job
---@param timeout number: set timeout, default 1000
function TestJob:start(timeout)
  return timeout
end

return TestJob
