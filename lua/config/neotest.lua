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
  "<leader>ns",
  "<cmd> Neotest summary <CR>",
  { desc = "Neotest open summary" }
)
map("n", "<leader>nr", function()
  neotest.run.run()
end, { desc = "Neotest run nearest test" })

map("n", "<leader>nwt", function()
  neotest.watch.watch()
end, { desc = "Neotest watch test" })

map("n", "<leader>no", function()
  neotest.output.open { enter = true }
end, { desc = "Neotest open output" })

map("n", "<leader>ndt", function()
  require("neotest").run.run { strategy = "dap" }
end, { desc = "Neotest debug nearest test" })
