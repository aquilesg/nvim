local M = {}

function M.insert_timestamp()
  local timestamp = tostring(os.date "- `%Y-%m-%d %H:%M:%S`")
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, { "" })
  vim.api.nvim_buf_set_text(0, row, 0, row, 0, { timestamp })
end

function M.create_disabled_markdown_lint_section()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1

  local disable = "<!-- markdownlint-disable-next-line -->"

  vim.api.nvim_buf_set_lines(0, line, line, false, { disable })
end

function M.toggle_diffview()
  if next(require("diffview.lib").views) == nil then
    vim.cmd "DiffviewOpen"
  else
    vim.cmd "DiffviewClose"
  end
end

function M.change_theme()
  local snacks = require "snacks"
  snacks.picker.colorschemes()
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
  telescope.extensions.live_grep_args.live_grep_args(
    require("telescope.themes").get_dropdown {}
  )
end

function M.list_open_buffers()
  local telescope_builtin = require "telescope.builtin"
  telescope_builtin.buffers(require("telescope.themes").get_dropdown {})
end

return M
