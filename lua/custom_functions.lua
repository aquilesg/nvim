local M = {}

function M.insert_timestamp()
  local timestamp = tostring(os.date "- `%Y-%m-%d %H:%M:%S`")
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, { "" })
  vim.api.nvim_buf_set_text(0, row, 0, row, 0, { timestamp })
end

function M.toggle_diffview()
  if next(require("diffview.lib").views) == nil then
    vim.cmd "DiffviewOpen"
  else
    vim.cmd "DiffviewClose"
  end
end

function M.load_test_suite()
  vim.cmd "Lazy load nvim-dap-ui"
  vim.cmd "Lazy load neotest"
  local map = vim.keymap.set
  local custom = require "custom_functions"
  map(
    "n",
    "<leader>tn",
    "<cmd> Neotest summary <CR>",
    { desc = "Neotest open summary" }
  )
  map(
    "n",
    "<leader>tr",
    require("neotest").run.run,
    { desc = "Neotest run nearest test" }
  )
  map(
    "n",
    "<leader>tw",
    require("neotest").watch.watch,
    { desc = "Neotest watch test" }
  )
  map("n", "<leader>to", custom.open_test, { desc = "Neotest open output" })
  map(
    "n",
    "<leader>td",
    custom.debug_nearest_test,
    { desc = "Neotest debug nearest test" }
  )
  map(
    "n",
    "<leader>tg",
    require("dap-go").debug_test,
    { desc = "Debug nearest go test" }
  )
  map("n", "<leader>du", require("dapui").toggle, { desc = "Toggle Dap UI" })
  map(
    "n",
    "<leader>dn",
    "<cmd> DapNew <CR>",
    { desc = "Start new DAP session" }
  )
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
end

function M.open_lazygit()
  local snacks = require "snacks"
  snacks.lazygit.open()
end

function M.find_files()
  local telescope_builtin = require "telescope.builtin"
  telescope_builtin.find_files {
    hidden = true,
    no_ignore = true,
    find_command = {
      "rg",
      "--files",
      "--hidden",
      "--no-ignore",
      "--glob",
      "!.git",
    },
  }
end

function M.livegrep()
  local telescope = require "telescope"
  telescope.extensions.live_grep_args.live_grep_args()
end
return M
