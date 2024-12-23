local map = vim.keymap.set
local custom = require "custom_functions"

-- AI Mapping
map("n", "<leader>n", "<cmd> CodeCompanionChat <CR>", { desc = "New CodeCompanionChat" })

-- Custom functions
map("n", "<leader>ts", custom.insert_timestamp, { desc = "Insert timestamp" })

-- Set dark or light themes
map("n", "<leader>sd", custom.set_dark_theme, { desc = "Set dark theme" })
map("n", "<leader>sl", custom.set_light_theme, { desc = "Set light theme" })

-- Custom Auto-commands
vim.api.nvim_create_user_command("LoadTestSuite", custom.load_test_suite, { desc = "Load test suite" })
