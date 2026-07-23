--  Nvim Tree Mappings
local map = vim.keymap.set
local is_brain = require("config.obsidian.vault").is_in_brain

map(
  "n",
  "<leader>jj",
  "<cmd> Noice dismiss <CR>",
  { desc = "Dismiss Noice notification" }
)
map(
  "n",
  "<leader>jk",
  ":nohlsearch<CR>",
  { silent = true, desc = "Clear search highlight" }
)
map("n", "<leader>x", "<cmd> bd <CR>", { desc = "Close current buffer" })

local reload_ui = function(_)
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
    "markdown.nvim",
    "bufferline.nvim",
  }

  for _, plugin in ipairs(ui_plugins) do
    local plugin_info = lazy.plugins()[plugin]
    if plugin_info and plugin_info._.working then
      require("lazy").reload { plugins = { plugin } }
    end
  end

  vim.cmd "bufdo e"
end

-- Persistent light/dark override.
--
-- By default the theme follows the system appearance (auto-dark-mode). Once you
-- manually toggle, the choice is written to a state file and wins on every
-- subsequent launch until you clear it (return to following the system).
local override_file = vim.fn.stdpath "state" .. "/theme_override"

-- Per-background colorscheme memory: whichever colorscheme you last selected
-- while in dark mode is remembered as your dark theme (and likewise for light),
-- so the choice survives a relaunch instead of resetting to the defaults below.
local colors_file = vim.fn.stdpath "state" .. "/theme_colors"
local default_colors = { dark = "ciapre", light = "lighty" }

local function read_override()
  local f = io.open(override_file, "r")
  if not f then
    return nil
  end
  local mode = f:read "*l"
  f:close()
  if mode == "light" or mode == "dark" then
    return mode
  end
  return nil
end

local function write_override(mode)
  local f = io.open(override_file, "w")
  if f then
    f:write(mode)
    f:close()
  end
end

local function clear_override()
  os.remove(override_file)
end

local function read_colors()
  local f = io.open(colors_file, "r")
  if not f then
    return vim.deepcopy(default_colors)
  end
  local data = f:read "*a"
  f:close()
  local ok, tbl = pcall(vim.json.decode, data)
  if not ok or type(tbl) ~= "table" then
    return vim.deepcopy(default_colors)
  end
  return {
    dark = tbl.dark or default_colors.dark,
    light = tbl.light or default_colors.light,
  }
end

local function write_colors(tbl)
  local f = io.open(colors_file, "w")
  if f then
    f:write(vim.json.encode(tbl))
    f:close()
  end
end

-- Set while we apply a theme ourselves, so the ColorScheme autocmd below does
-- not treat our own colorscheme call as a fresh user selection.
local applying = false

local function apply_theme(mode)
  local colors = read_colors()
  applying = true
  vim.api.nvim_set_option_value("background", mode, {})
  vim.cmd.colorscheme(colors[mode])
  applying = false
  reload_ui()
end

-- Remember the colorscheme picked for the active background (e.g. via <leader>C).
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    if applying then
      return
    end
    local name = vim.g.colors_name
    if not name then
      return
    end
    local bg = vim.o.background
    local colors = read_colors()
    if colors[bg] ~= name then
      colors[bg] = name
      write_colors(colors)
    end
  end,
})

-- Toggle light <-> dark and persist the choice.
map("n", "<leader>ut", function()
  local current = read_override() or vim.o.background
  local next_mode = current == "dark" and "light" or "dark"
  write_override(next_mode)
  apply_theme(next_mode)
end, { desc = "Toggle light/dark theme (persistent)" })

-- Drop the override and follow the system appearance again.
map("n", "<leader>uT", function()
  clear_override()
  local style = vim.fn.system "defaults read -g AppleInterfaceStyle 2>/dev/null"
  apply_theme(style:match "Dark" and "dark" or "light")
end, { desc = "Theme: follow system (clear override)" })

return {
  {
    "f-person/auto-dark-mode.nvim",
    event = "VeryLazy",
    opts = {
      -- A saved override wins over the system appearance; otherwise follow it.
      set_dark_mode = function()
        apply_theme(read_override() or "dark")
      end,
      set_light_mode = function()
        apply_theme(read_override() or "light")
      end,
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
  },
  {
    lazy = true,
    "neanias/everforest-nvim",
  },
  {
    lazy = true,
    "e-ink-colorscheme/e-ink.nvim",
  },
  {
    lazy = true,
    "cdmill/neomodern.nvim",
  },
  {
    lazy = true,
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    lazy = false,
    "rktjmp/lush.nvim",
    { dir = "~/Repos/ciapre/", lazy = true },
    { dir = "~/Repos/lighty/", lazy = true },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
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
    keys = {
      {
        "<c-n>",
        "<cmd> NvimTreeToggle <cr>",
        desc = "Open Nvim Tree",
      },
      {
        "<leader>e",
        "<cmd> NvimTreeFocus <cr>",
        desc = "Focus Nvim Tree",
      },
    },
    opts = {
      git = {
        timeout = 5000,
      },
      filters = {
        git_ignored = false,
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
      auto_close = true,
      focus = true,
      win = {
        type = "split",
        position = "left",
        size = 0.35,
      },
      preview = {
        type = "split",
        relative = "win",
        position = "right",
        size = 0.6,
      },
      modes = {
        lsp_base = {
          focus = true,
        },
        symbols = {
          focus = true,
        },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
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
    event = "BufEnter",
    opts = {
      render = "foreground",
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
      completions = { lsp = { enabled = true } },
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
      code = {
        sign = false,
        border = "thin",
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
    "akinsho/bufferline.nvim",
    keys = {
      {
        "<Tab>",
        "<cmd> BufferLineCycleNext <cr>",
        desc = "Cycle Bufferline Next",
      },
      {
        "<S-Tab>",
        "<cmd> BufferLineCyclePrev <cr>",
        desc = "Cycle Bufferline Next",
      },
    },
    version = "*",
    event = "UIEnter",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      local bufferline = require "bufferline"
      bufferline.setup {
        options = {
          name_formatter = function(buf)
            local name = vim.b[buf.bufnr] and vim.b[buf.bufnr].obsidian_alias
              or buf.name
            local devicons = require "nvim-web-devicons"
            local icon, _ =
              devicons.get_icon(buf.name, buf.extension, { default = true })
            if icon then
              name = name .. " " .. icon
            end
            return name
          end,
          style_preset = bufferline.style_preset.default,
          themable = false,
          indicator = {
            style = "underline",
          },
          modified_icon = "󰳼 ",
          offsets = {
            {
              filetype = "NvimTree",
              text = "  File Explorer",
              text_align = "left",
              separator = true,
            },
          },
          separator_style = "slope",
          color_icons = false,
          groups = {
            items = {
              {
                name = " PRs",
                matcher = function(buf)
                  return vim.api.nvim_get_option_value("filetype", {
                    buf = buf.id,
                  }) == "octo"
                end,
              },
              {
                name = "󱥊 Infra",
                matcher = function(buf)
                  return vim.api.nvim_buf_get_name(buf.id):match "%.tf$"
                end,
              },
              {
                name = " Configs",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return get_buf(buf.id):match "%.yaml$"
                    or get_buf(buf.id):match "%.yml$"
                end,
              },
              {
                name = " Brain",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return get_buf(buf.id):match "%.md$" and is_brain(buf.id)
                end,
              },
              {
                name = "󰈙 Docs",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return (
                    get_buf(buf.id):match "%.md$"
                    or get_buf(buf.id):match "%.txt$"
                  ) and not is_brain(buf.id)
                end,
              },
              {
                name = " Go",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return get_buf(buf.id):match "%.go$"
                end,
              },
              {
                name = " Python",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return get_buf(buf.id):match "%.py$"
                end,
              },
              {
                name = " Bash",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return get_buf(buf.id):match "%.sh$"
                end,
              },
              {
                name = "󰢱 Lua",
                matcher = function(buf)
                  local get_buf = vim.api.nvim_buf_get_name
                  return get_buf(buf.id):match "%.lua$"
                end,
              },
            },
          },
        },
      }
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "folke/noice.nvim",
      "franco-ruggeri/codecompanion-lualine.nvim",
    },
    event = "UIEnter",
    config = function(_, opts)
      require("config.obsidian.pomodoro").setup()
      require("lualine").setup(opts)
    end,
    opts = {
      options = {
        globalstatus = true,
      },
      sections = {
        lualine_x = {
          "codecompanion",
          {
            function()
              return require("config.obsidian.pomodoro").statusline()
            end,
            cond = function()
              return require("config.obsidian.pomodoro").cache.status
                ~= "stopped"
            end,
          },
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
          {
            function()
              local ft = vim.bo.filetype
              if ft == "toggleterm" then
                local num = vim.b.toggle_number or ""
                return "terminal (" .. num .. ")"
              end
              return ""
            end,
            cond = function()
              return vim.bo.filetype == "toggleterm"
            end,
            icon = "",
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
    lazy = false,
    config = function()
      require("nvim-treesitter")
        .install({
          "go",
          "lua",
          "python",
          "bash",
          "markdown",
          "yaml",
          "json",
          "terraform",
          "hcl",
          "rust",
          "javascript",
        })
        :wait(300000)
    end,
    build = ":TSUpdate",
  },
}
