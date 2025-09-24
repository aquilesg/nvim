vim.treesitter.language.register("markdown", "octo")

return {
  {
    "oribarilan/lensline.nvim",
    tag = "1.0.0", -- or: branch = 'release/1.x' for latest non-breaking updates
    event = "LspAttach",
    config = function()
      require("lensline").setup()
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      {
        "<leader>hs",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.stage_hunk()
        end,
        desc = "Git stage hunk",
        mode = "n",
      },
      {
        "<leader>hr",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.reset_hunk()
        end,
        desc = "Git reset hunk",
        mode = "n",
      },
      {
        "<leader>hs",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
        end,
        desc = "Stage visuall selected Hunk",
        mode = "v",
      },
      {
        "<leader>hr",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
        end,
        desc = "Rest visually selected hunk",
        mode = "v",
      },
      {
        "<leader>hS",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.stage_buffer()
        end,
        desc = "Git stage buffer",
        mode = "n",
      },
      {
        "<leader>hu",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.stage_hunk()
        end,
        desc = "Git undo stage hunk",
        mode = "n",
      },
      {
        "<leader>hR",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.reset_buffer()
        end,
        desc = "Git reset buffer",
        mode = "n",
      },
      {
        "<leader>hp",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.preview_hunk()
        end,
        desc = "Git preview hunk",
        mode = "n",
      },
      {
        "<leader>hb",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.toggle_current_line_blame()
        end,
        desc = "Git toggle current line blame",
        mode = "n",
      },
      {
        "<leader>hd",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.diffthis()
        end,
        desc = "Git diff this",
        mode = "n",
      },
      {
        "<leader>hD",
        function()
          local gitsigns = require "gitsigns"
          gitsigns.diffthis "~"
        end,
        desc = "Git diff this",
      },
    },
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require "gitsigns"
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal { "]c", bang = true }
          else
            gitsigns.nav_hunk "next"
          end
        end)

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal { "[c", bang = true }
          else
            gitsigns.nav_hunk "prev"
          end
        end)
      end,
    },
    event = "VeryLazy",
  },
  {
    "pwntester/octo.nvim",
    commit = "5a2b3f462bf7d4ebb83819e6f265c6c8ae9c9b42",
    keys = {
      {
        "<leader>1",
        "<cmd> Octo pr create draft <CR>",
        desc = "Create new draft PR",
      },
      {
        "<leader>2",
        "<cmd> Octo pr list <CR>",
        desc = "List PRs for this repo",
      },
      {
        "<leader>3",
        "<cmd> Octo pr search <CR>",
        desc = "Search for PR",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      users = "assignable",
    },
  },
  {
    {
      "Rawnly/gist.nvim",
      cmd = { "GistCreate", "GistCreateFromFile", "GistsList" },
      opts = {},
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    keys = {
      {
        "<leader>dvv",
        function()
          if next(require("diffview.lib").views) == nil then
            vim.cmd "DiffviewOpen"
          else
            vim.cmd "DiffviewClose"
          end
        end,
        desc = "Toggle Diffview",
      },
    },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    },
  },
  {
    "FabijanZulj/blame.nvim",
    keys = {
      {
        "<leader>ge",
        "<cmd> BlameToggle <CR>",
        desc = "Toggle git blame",
      },
    },
    opts = {},
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = { "Neogit" },
    opts = {
      process_spinner = true,
    },
  },
  {
    "linrongbin16/gitlinker.nvim",
    cmd = "GitLink",
    opts = {},
    keys = {
      {
        "<leader>gy",
        "<cmd>GitLink<cr>",
        mode = { "n", "v" },
        desc = "Yank git link",
      },
      {
        "<leader>gY",
        "<cmd>GitLink!<cr>",
        mode = { "n", "v" },
        desc = "Open git link",
      },
    },
  },
}
