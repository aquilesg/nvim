local dap = require "dap"
local map = vim.keymap.set

-- Mappings
map("n", "<leader>du", require("dapui").toggle, { desc = "Toggle Dap UI" })
map("n", "<leader>dn", "<cmd> DapNew <CR>", { desc = "Start new DAP session" })
map("n", "<leader>dc", "<cmd> DapContinue <CR>", { desc = "Continue Dap" })
map(
  "n",
  "<leader>dt",
  "<cmd> DapTerminate <CR>",
  { desc = "Terminate session" }
)
map(
  "n",
  "<leader>db",
  "<cmd> DapToggleBreakpoint <CR>",
  { desc = "Toggle breakpoint" }
)
map("n", "<leader>dso", "<cmd> DapStepOver <CR>", { desc = "DapStepOver" })
map("n", "<leader>dsi", "<cmd> DapStepInto <CR>", { desc = "DapStepInto" })
map("n", "<leader>dsO", "<cmd> DapStepOut <CR>", { desc = "DapStepOut" })
map("n", "<leader>drr", require("dap").restart, { desc = "Dap restart" })
map("n", "<leader>drl", require("dap").run_last, { desc = "Dap run last" })
map(
  { "n", "v" },
  "<leader>dh",
  require("dap.ui.widgets").hover,
  { desc = "Evaluate value under cursor" }
)
map(
  { "n", "v" },
  "<leader>dp",
  require("dap.ui.widgets").preview,
  { desc = "Preview" }
)
map("n", "<leader>dvf", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.frames)
end, { desc = "View Frames" })
map("n", "<leader>dvs", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.scopes)
end, { desc = "View scopes" })

-- DAP configurations
dap.adapters.nlua = function(callback, config)
  callback {
    type = "server",
    host = config.host or "127.0.0.1",
    port = config.port or 8086,
  }
end

local dapui = require "dapui"
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

require("dap-python").setup "python3"
