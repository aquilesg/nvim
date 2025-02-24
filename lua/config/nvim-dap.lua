local dap = require "dap"
local map = vim.keymap.set

-- Configure python debugger
require("dap-python").setup "~/.virtualenvs/debugpy/bin/python"

-- Configure go debugger
-- Setup adapters
require("dap-go").setup {
  delve = {
    initialize_timeout_sec = 45,
  },
  dap_configurations = {
    {
      type = "go",
      name = "Debug (Build Flags)",
      request = "launch",
      program = "${file}",
      buildFlags = require("dap-go").get_build_flags,
    },
  },
}

local dapui = require "dapui"
dap.listeners.before.attach.dapui_config = function()
  dapui.open { reset = true }
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open { reset = true }
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.open { reset = true }
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.open { reset = true }
end

map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "Continue Dap" })

map("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "Terminate session" })

map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })

map("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
    vim.ui.input({ prompt = "Hit condition: " }, function(hit_condition)
      vim.ui.input({ prompt = "Log message: " }, function(log_message)
        require("dap").set_breakpoint(
          condition ~= "" and condition or nil,
          hit_condition ~= "" and hit_condition or nil,
          log_message ~= "" and log_message or nil
        )
      end)
    end)
  end)
end, { desc = "Set conditional breakpoint" })

map("n", "<leader>dso", function()
  require("dap").step_over()
end, { desc = "DapStepOver" })

map("n", "<leader>dsi", function()
  require("dap").step_into()
end, { desc = "DapStepInto" })

map("n", "<leader>dsO", function()
  require("dap").step_out()
end, { desc = "DapStepOut" })

map("n", "<leader>drr", function()
  require("dap").restart()
end, { desc = "Dap restart" })

map("n", "<leader>drl", function()
  require("dap").run_last()
end, { desc = "Dap run last" })

map({ "n" }, "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Evaluate value under cursor" })

map({ "n" }, "<leader>dp", function()
  require("dap.ui.widgets").preview()
end, { desc = "Preview" })

map("n", "<leader>dvf", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.frames)
end, { desc = "View Frames" })

map("n", "<leader>dvs", function()
  local widgets = require "dap.ui.widgets"
  widgets.centered_float(widgets.scopes)
end, { desc = "View scopes" })

map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Toggle Dap UI" })
