local Job = require "plenary.job"

local rpc = require "nlsp.rpc"

local j = Job:new {
  command = "nvim",
  args = { "--headless", "-c", 'lua require("nlsp").start()' },
}

j:start()

rpc.send_message({
  method = "initialize",
  params = { 1, 2, 3 },
}, j.stdin)
