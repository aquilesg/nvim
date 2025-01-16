local map = vim.keymap.set
local custom = require "custom_functions"

-- Custom functions
map("n", "<leader>is", custom.insert_timestamp, { desc = "Insert timestamp" })
map(
  "n",
  "<leader>im",
  custom.create_disabled_markdown_lint_section,
  { desc = "Create disabled markdown lint section" }
)

map("n", "<leader>C", custom.change_theme, { desc = "Change colorscheme" })
