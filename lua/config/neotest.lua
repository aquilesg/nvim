require("neotest").setup {
  adapters = {
    require "neotest-python" {
      dap = { justMyCode = false },
    },
    require "neotest-go" {},
  },
}

-- Neotest
local map = vim.keymap.set
local neotest = require "neotest"
map(
  "n",
  "<leader>tn",
  "<cmd> Neotest summary <CR>",
  { desc = "Neotest open summary" }
)
map("n", "<leader>tr", neotest.run.run, { desc = "Neotest run nearest test" })

map("n", "<leader>tw", neotest.watch.watch, { desc = "Neotest watch test" })

local open_test = function()
  neotest.output.open { enter = true }
end

local debug_test = function()
  local filetype = vim.bo.filetype
  if filetype == "go" then
    return require("dap-go").debug_test
  elseif filetype == "python" then
    return require("dap-python").test_method
  end
end

map("n", "<leader>to", open_test, { desc = "Neotest open output" })
map("n", "<leader>td", debug_test, { desc = "Neotest debug nearest test" })
