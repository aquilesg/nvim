return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = function()
    local function nav(lhs, fn, desc)
      return {
        lhs,
        function()
          require("smart-splits")[fn]()
        end,
        mode = "t",
        desc = desc,
      }
    end
    return {
      terminal = {
        provider = "snacks",
        snacks_win_opts = {
          keys = {
            nav_left = nav("<C-h>", "move_cursor_left", "Move to left split"),
            nav_down = nav("<C-j>", "move_cursor_down", "Move to split below"),
            nav_up = nav("<C-k>", "move_cursor_up", "Move to split above"),
            nav_right = nav("<C-l>", "move_cursor_right", "Move to right split"),
          },
        },
      },
    }
  end,
  keys = {
    { "<leader>a", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>a", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude Code" },
    { "<C-a>", "<cmd>ClaudeCode<cr>", mode = "t", desc = "Toggle Claude Code" },
  },
}
