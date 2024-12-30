local map = vim.keymap.set
local custom = require "custom_functions"

-- Custom functions
map("n", "<leader>ts", custom.insert_timestamp, { desc = "Insert timestamp" })
