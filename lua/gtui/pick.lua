local M = {}

-- opts: prompt, format(item) -> string, preview(item) -> lines (optional),
-- on_url(text) (optional) handles a pasted URL typed into the prompt
function M.select(items, opts, on_choice)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    return vim.ui.select(items, { prompt = opts.prompt, format_item = opts.format }, on_choice)
  end
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local previewers = require "telescope.previewers"
  pickers
    .new({}, {
      prompt_title = opts.prompt,
      finder = finders.new_table {
        results = items,
        entry_maker = function(item)
          local text = opts.format(item)
          return { value = item, display = text, ordinal = text }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = opts.preview and previewers.new_buffer_previewer {
        title = "Panels",
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, opts.preview(entry.value))
          vim.bo[self.state.bufnr].filetype = "markdown"
        end,
      },
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          local text = action_state.get_current_line()
          actions.close(bufnr)
          if opts.on_url and text:match "^https?://" then
            opts.on_url(vim.trim(text))
          elseif entry then
            on_choice(entry.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
