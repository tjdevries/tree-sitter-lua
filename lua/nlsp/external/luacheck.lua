-- alloyed/lua-lsp
-- ty ty

local popen_cmd = "sh -c 'cd %q; luacheck %q --filename %q --formatter plain --ranges --codes'"
local message_match = "^([^:]+):(%d+):(%d+)%-(%d+): %(W(%d+)%) (.+)"
local function try_luacheck(document)
  local diagnostics = {}
  local opts = {}
  if luacheck then
    local reports
    if Config._useNativeLuacheck == false then
      local tmp_path = "/tmp/check.lua"
      local tmp = assert(io.open(tmp_path, "w"))
      tmp:write(document.text)
      tmp:close()

      local _, ce = document.uri:find(Config.root, 1, true)
      local fname = document.uri:sub((ce or -1) + 2, -1):gsub("file://", "")
      local root = Config.root:gsub("file://", "")
      local issues = io.popen(popen_cmd:format(root, tmp_path, fname))
      reports = { {} }
      for line in issues:lines() do
        local _, l, scol, ecol, code, msg = line:match(message_match)
        assert(tonumber(l), line)
        assert(tonumber(scol), line)
        assert(tonumber(ecol), line)
        table.insert(reports[1], {
          code = code,
          line = tonumber(l),
          column = tonumber(scol),
          end_column = tonumber(ecol),
          message = msg,
        })
      end
      issues:close()
    else
      reports = luacheck.check_strings({ document.text }, { opts })
    end

    for _, issue in ipairs(reports[1]) do
      -- FIXME: translate columns to characters
      table.insert(diagnostics, {
        code = issue.code,
        range = {
          start = {
            line = issue.line - 1,
            character = issue.column - 1,
          },
          ["end"] = {
            line = issue.line - 1,
            character = issue.end_column,
          },
        },
        -- 1 == error, 2 == warning
        severity = issue.code:find "^0" and 1 or 2,
        source = "luacheck",
        message = issue.message or luacheck.get_message(issue),
      })
    end
  end
  rpc.notify("textDocument/publishDiagnostics", {
    uri = document.uri,
    diagnostics = diagnostics,
  })
end
