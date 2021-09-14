return require("plenary.log").new {
  plugin = "nlsp",
  level = (vim.loop.os_getenv "USER" == "tj" and "trace") or "info",
}
