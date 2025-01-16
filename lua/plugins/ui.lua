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
  -- Check for modified buffers
  local modified_buffers = {}
  for _, buf in ipairs(vim.fn.getbufinfo()) do
    if buf.changed == 1 then
      table.insert(modified_buffers, buf.name)
    end
  end

  if #modified_buffers > 0 then
    local choice = vim.fn.confirm(
      "You have unsaved changes. Save before changing theme?",
      "&Yes\n&No\n&Cancel",
      1
    )
    if choice == 1 then
      vim.cmd "wa"
    elseif choice == 3 then
      return
    end
  end

  vim.api.nvim_set_option_value("background", background_option, {})

  -- Reload the color theme
  if background_option == "light" then
    vim.cmd "colorscheme tokyonight-day"
  else
    vim.cmd "colorscheme duskfox"
  end

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
local treesitter_parsers = {
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
}

return {
  {
    "f-person/auto-dark-mode.nvim",
    priority = 1000,
    lazy = false,
    opts = {
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
  },
  { "ramojus/mellifluous.nvim" },
  { "folke/tokyonight.nvim" },
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    "EdenEast/nightfox.nvim",
  },
  {
    "folke/noice.nvim",
    event = "UIEnter",
    opts = {
      lsp = {
        signature = { enabled = false },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
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
    event = "VeryLazy",
    opts = {
      git = {
        timeout = 1000,
      },
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
    opts = {
      keywords = {
        AQUILES = {
          icon = " ",
          color = "hint",
          alt = { "aquiles", "Aquiles" },
        },
      },
    },
  },
  {
    "winston0410/range-highlight.nvim",
    event = "BufEnter",
    dependencies = { "winston0410/cmd-parser.nvim" },
  },
  {
    "brenoprata10/nvim-highlight-colors",
    event = "UIEnter",
    opts = {
      render = "foreground",
    },
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
        enabled = false,
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
      picker = {},
      indent = {
        only_scope = true,
      },
      scroll = {},
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
    "akinsho/bufferline.nvim",
    version = "*",
    event = "UIEnter",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      local bufferline = require "bufferline"
      bufferline.setup {
        options = {
          style_preset = bufferline.style_preset.default,
          themable = false,
          indicator = {
            style = "underline",
          },
          modified_icon = "󰳼 ",
          offsets = {
            {
              filetype = "NvimTree",
              text = "  File Explorer",
              text_align = "left",
              separator = true,
            },
          },
          separator_style = "slope",
          color_icons = false,
        },
      }
    end,
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
              local buf_clients = vim.lsp.get_clients { bufnr = 0 }
              if #buf_clients == 0 then
                return ""
              end
              local buf_client_names = {}
              for _, client in pairs(buf_clients) do
                table.insert(buf_client_names, " " .. client.name)
              end
              return table.concat(buf_client_names, ", ")
            end,
            icon = "LSP(s):",
            cond = function()
              local buf_clients = vim.lsp.get_clients { bufnr = 0 }
              return #buf_clients > 0
            end,
          },
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return require("noice").api.status.mode.has()
            end,
            color = { gui = "bold" },
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
  {
    "nvim-treesitter/nvim-treesitter",
    event = "UIEnter",
    config = function()
      require("nvim-treesitter.configs").setup {
        auto_install = true,
        ensure_installed = treesitter_parsers,
        highlight = {
          enable = true,
        },
      }
    end,
  },
}
