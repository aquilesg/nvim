--  Nvim Tree Mappings
local map = vim.keymap.set

map(
  "n",
  "<leader>jj",
  "<cmd> Noice dismiss <CR>",
  { desc = "Dismiss Noice notification" }
)
map("n", "<leader>x", "<cmd> bd <CR>", { desc = "Close current buffer" })
map(
  "n",
  "<leader>/",
  ":nohlsearch<CR>",
  { silent = true, desc = "Clear search highlight" }
)

-- Nvim Tree
map({ "n" }, "<c-n>", "<cmd> NvimTreeToggle <cr>", { desc = "Open Nvim Tree" })
map(
  { "n" },
  "<leader>e",
  "<cmd> NvimTreeFocus <cr>",
  { desc = "Focus Nvim Tree" }
)

-- Trouble Diagnostics
map(
  "n",
  "<leader>qt",
  "<cmd> Trouble diagnostics toggle <CR>",
  { desc = "Toggle Trouble over workspace" }
)
map(
  "n",
  "<leader>qb",
  "<cmd> Trouble diagnostics toggle filter.buf=0 <CR>",
  { desc = "Toggle buffer diagnostics" }
)
map("n", "<leader>qa", "<cmd> TodoTrouble <CR>", { desc = "Toggle TODO list" })

-- Document symbols
map(
  "n",
  "go",
  "<cmd> Trouble symbols toggle focus=true pinned=true results.win.relative=win results.win.position=right <CR>",
  { desc = "Show outline" }
)

local set_plugin_theme = function(background_option)
  vim.api.nvim_set_option_value("background", background_option, {})

  -- Reload the color theme
  vim.cmd "colorscheme rose-pine"

  -- Close unnamed buffers
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_get_name(buf) == "" then
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end

  -- Reload UI Plugins
  local lazy = require "lazy"
  local ui_plugins = {
    "tiny-inline-diagnostic.nvim",
    "markdown.nvim",
    "drop.nvim",
  }

  for _, plugin in ipairs(ui_plugins) do
    local plugin_info = lazy.plugins()[plugin]
    if plugin_info and plugin_info._.working then
      vim.cmd("Lazy reload " .. plugin)
    end
  end

  vim.cmd "bufdo e"
end

return {
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      update_interval = 1000,
      set_dark_mode = function()
        set_plugin_theme "dark"
      end,
      set_light_mode = function()
        set_plugin_theme "light"
      end,
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "auto",
      dark_variant = "moon",
      dim_inactive_windows = true,
    },
  },
  {
    "folke/noice.nvim",
    event = "UIEnter",
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
    event = "UIEnter",
    opts = {
      hijack_cursor = true,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      renderer = {
        root_folder_label = false,
        highlight_git = true,
        indent_markers = { enable = true },
        icons = {
          glyphs = {
            git = { unmerged = "" },
          },
        },
      },
    },
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
    event = "UIEnter",
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
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      heading = {
        width = { "full", "block", "full", "block" },
        min_width = 30,
      },
      preset = "obsidian",
      callout = {
        done = {
          raw = "[!Done]",
          rendered = "󰄬 Done",
          highlight = "RenderMarkdownSuccess",
        },
        info = {
          raw = "[!info]",
          rendered = "󰋽 Info",
          highlight = "RenderMarkdownInfo",
        },
        time = {
          raw = "[!timestamp]",
          rendered = " Timestamp",
          highlight = "RenderMarkdownInfo",
        },
      },
      checkbox = {
        custom = {
          todo = {
            raw = "[-]",
            rendered = "󰥔 ",
            highlight = "RenderMarkdownTodo",
          },
          follow_up = {
            raw = "[>]",
            rendered = " ",
            highlight = "RenderMarkdownTodo",
          },
          canceled = {
            raw = "[~]",
            rendered = "󰰱 ",
            highlight = "RenderMarkdownTodo",
          },
          important = {
            raw = "[!]",
            rendered = " ",
            highlight = "RenderMarkdownTodo",
          },
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
    event = "UIEnter",
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
          { section = "keys", gap = 1, padding = 1 },
          {
            pane = 2,
            icon = " ",
            desc = "Browse Repo",
            padding = 1,
            key = "b",
            action = function()
              Snacks.gitbrowse()
            end,
          },
          function()
            local in_git = Snacks.git.get_root() ~= nil
            local cmds = {
              {
                icon = " ",
                title = "Open PRs",
                cmd = "gh pr list -L 3",
                key = "p",
                action = function()
                  vim.fn.jobstart("gh pr list --web", { detach = true })
                end,
                height = 7,
              },
              {
                icon = " ",
                title = "Git Status",
                cmd = "git --no-pager diff --stat -B -M -C",
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
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "folke/noice.nvim" },
    event = "UIEnter",
    opts = {
      options = {
        globalstatus = true,
      },
      sections = {
        lualine_x = {
          {
            function()
              return require("noice").api.status.message.get_hl()
            end,
            cond = function()
              return require("noice").api.status.message.has()
            end,
          },
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return require("noice").api.status.mode.has()
            end,
            color = { fg = "#ff9e64" },
          },
          {
            function()
              return require("noice").api.status.search.get()
            end,
            cond = function()
              return require("noice").api.status.search.has()
            end,
            color = { fg = "#ff9e64" },
          },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "UIEnter",
    opts = {},
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show { global = true }
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
