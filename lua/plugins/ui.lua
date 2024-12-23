--  Nvim Tree Mappings
local map = vim.keymap.set

map("n", "<leader>jj", "<cmd> Noice dismiss <CR>", { desc = "Dismiss Noice notification" })
map("n", "<leader>x", "<cmd> bd <CR>", { desc = "Close current buffer" })

-- Nvim Tree
map({ "n", "i" }, "<c-n>", "<cmd> NvimTreeToggle <cr>", { desc = "Open Nvim Tree" })
map({ "n", "i" }, "<leader>e", "<cmd> NvimTreeFocus <cr>", { desc = "Focus Nvim Tree" })

-- Trouble Diagnostics
map("n", "<leader>qt", "<cmd> Trouble diagnostics toggle <CR>", { desc = "Toggle Trouble over workspace" })
map("n", "<leader>qb", "<cmd> Trouble diagnostics toggle filter.buf=0 <CR>", { desc = "Toggle buffer diagnostics" })
map("n", "<leader>qa", "<cmd> TodoTrouble <CR>", { desc = "Toggle TODO list" })

-- Document symbols
map(
  "n",
  "go",
  "<cmd> Trouble symbols toggle focus=true pinned=true results.win.relative=win results.win.position=right <CR>",
  { desc = "Show outline" }
)

return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.cmd("colorscheme rose-pine")
    end
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      presets = {
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    opts = {},
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },
  {
    "folke/trouble.nvim",
    event = "LspAttach",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      modes = {
        symbols = {
          focus = true,
          win = {
            type = "float",
          },
        },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "LspAttach",
    opts = {},
  },
  {
    "winston0410/range-highlight.nvim",
    event = "BufEnter",
    dependencies = { "winston0410/cmd-parser.nvim" },
  },
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.6,
      trailing_exponent = 0,
      distance_stop_animating = 0.5,
      hide_target_hack = false,
    },
  },
  {
    "MeanderingProgrammer/markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      preset = "obsidian",
      callout = {
        done = { raw = "[!Done]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
        info = { raw = "[!info]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
        time = { raw = "[!timestamp]", rendered = " Timestamp", highlight = "RenderMarkdownInfo" },
      },
      checkbox = {
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          follow_up = { raw = "[>]", rendered = " ", highlight = "RenderMarkdownTodo" },
          canceled = { raw = "[~]", rendered = "󰰱 ", highlight = "RenderMarkdownTodo" },
          important = { raw = "[!]", rendered = " ", highlight = "RenderMarkdownTodo" },
        },
      },
      pipe_table = { preset = "heavy" },
      html = {
        enabled = true,
        conceal_comments = false,
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "OXY2DEV/helpview.nvim",
    ft = "help",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "folke/drop.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      indent = {
        only_scope = true,
      },
      quickfile = { enabled = true },
      dashboard = {
        enabled = true,
        sections = {
          { section = "header" },
          { section = "keys",  gap = 1, padding = 1 },
          function()
            local Snacks = require "snacks"
            Snacks.scroll.enable()
            local in_git = Snacks.git.get_root() ~= nil
            local cmds = {
              {
                icon = " ",
                title = "Open PRs",
                cmd = "gh pr list -L 3",
                height = 7,
              },
              {
                icon = " ",
                title = "Git Status",
                cmd = "hub --no-pager diff --stat -B -M -C",
                height = 10,
              },
            }
            return vim.tbl_map(function(cmd)
              return vim.tbl_extend("force", {
                pane = 2,
                section = "terminal",
                enabled = in_git,
                padding = 1,
                ttl = 5 * 60,
                indent = 3,
              }, cmd)
            end, cmds)
          end,
          { section = "startup" },
        },
      },
    },
    lazy = false,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      auto_install = true,
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "dockerfile",
        "go",
        "hcl",
        "html",
        "graphql",
        "java",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "mermaid",
        "python",
        "proto",
        "ruby",
        "scala",
        "sql",
        "terraform",
        "vim",
        "vimdoc",
        "yaml",
      },
      highlight = {
        enable = true,
      },
    }
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      disabled_filetypes = {
        statusline = { 'NvimTree' }
      },
      sections = {
        lualine_x = {
          {
            require("noice").api.status.message.get_hl,
            cond = require("noice").api.status.message.has,
          },
          {
            require("noice").api.status.mode.get,
            cond = require("noice").api.status.mode.has,
            color = { fg = "#ff9e64" },
          },
          {
            require("noice").api.status.search.get,
            cond = require("noice").api.status.search.has,
            color = { fg = "#ff9e64" },
          },
        },
      },
    },
  },
}
