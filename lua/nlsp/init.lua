local log = require "nlsp.log"
local rpc = require "nlsp.rpc"

local M = {}

-- io.stderr:setvbuf("no")
Shutdown = Shutdown or false

local method_handlers = {}

M.start = function()
  local ok, msg = pcall(function()
    log.info "We started"

    while not Shutdown do
      -- header
      local err, data = rpc.read_message()
      log.info("Message is:", err, data)

      -- if _G.Config.debugMode then
      --   reload_all()
      -- end

      if data == nil then
        if err == "eof" then
          return os.exit(1)
        end
        error(err)
      elseif data.method then
        -- request
        if not method_handlers[data.method] then
          log.info("confused by %t", data)
          err = string.format("%q: Not found/NYI", tostring(data.method))
          if data.id then
            rpc.respondError(data.id, err, "MethodNotFound")
          else
            log.warning("%s", err)
          end
        else
          local ok
          ok, err = xpcall(function()
            method_handlers[data.method](data.params, data.id)
          end, debug.traceback)
          if not ok then
            if data.id then
              rpc.respondError(data.id, err, "InternalError")
            else
              log.warning("%s", tostring(err))
            end
          end
        end
      elseif data.result then
        rpc.finish(data)
      elseif data.error then
        log("client error:%s", data.error.message)
      end
    end

    os.exit(0)
  end)

  if not ok then
    log.info("ERROR:", msg)
  end
end

return M
