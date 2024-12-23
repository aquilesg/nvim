local map = vim.keymap.set
map(
  { "n", "v" },
  "<C-a>",
  "<cmd>CodeCompanionActions<cr>",
  { noremap = true, silent = true, desc = "Open CodeCompanionActions" }
)
map(
  { "n", "v" },
  "<Leader>a",
  "<cmd>CodeCompanionChat Toggle<cr>",
  { noremap = true, silent = true, desc = "Toggle CodeCompanionChat" }
)
map(
  "v",
  "ga",
  "<cmd>CodeCompanionChat Add<cr>",
  { noremap = true, silent = true, desc = "Add selected visual section to chat" }
)

vim.treesitter.language.register("markdown", "codecompanion")

return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanionActions", "CodeCompanionChat" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
      { "echasnovski/mini.nvim",  version = false },
      { "stevearc/dressing.nvim", opts = {} },
    },
    opts = {
      display = {
        chat = {
          render_headers = false,
        },
        diff = {
          provider = "mini_diff",
        },
      },
      strategies = {
        chat = {
          adapter = "anthropic",
        },
        agent = {
          adapter = "anthropic",
        },
      },
      adapters = {
        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = os.getenv "OPENAI_API_KEY",
            },
          })
        end,
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = os.getenv "ANTHROPIC_API_KEY",
            },
          })
        end,
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    },
  },
}
