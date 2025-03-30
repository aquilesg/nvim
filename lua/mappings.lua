local map = vim.keymap.set

-- Custom functions
map("n", "<leader>is", function()
  local timestamp = tostring(os.date "- `%Y-%m-%d %H:%M:%S`")
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, { "" })
  vim.api.nvim_buf_set_text(0, row, 0, row, 0, { timestamp })
end, { desc = "Insert timestamp" })

map("n", "<leader>im", function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local disable = "<!-- markdownlint-disable-next-line -->"
  vim.api.nvim_buf_set_lines(0, line, line, false, { disable })
end, { desc = "Create disabled markdown lint section" })
