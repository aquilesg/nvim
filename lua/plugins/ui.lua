--  Nvim Tree Mappings
local map = vim.keymap.set
local is_brain = require("config.obsidian.vault").is_in_brain
local is_mac = require("config.platform").is_mac

-- Optional modules: lualine re-raises render errors, so an unguarded require in
-- a component breaks the whole statusline instead of just its own segment.
local function optional(module)
  local ok, mod = pcall(require, module)
  return ok and mod or nil
end

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

-- The primary themes live in local checkouts under ~/Repos; fall back to a
-- bundled scheme on machines that do not have them.
local function apply_colorscheme(name, fallback)
  if not pcall(vim.cmd.colorscheme, name) then
    vim.cmd.colorscheme(fallback)
  end
end

return {
  {
    "f-person/auto-dark-mode.nvim",
    event = "VeryLazy",
    opts = {
      set_dark_mode = function()
        apply_colorscheme("ciapre", "tokyonight-night")
        vim.api.nvim_set_option_value("background", "dark", {})
        reload_ui()
      end,
      set_light_mode = function()
        apply_colorscheme("rose-pine-dawn", "tokyonight-day")
        vim.api.nvim_set_option_value("background", "light", {})
        reload_ui()
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
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
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

      -- Build a bufferline group matching any of `exts`. The icon is taken
      -- from `icon` when given, otherwise auto-derived from nvim-web-devicons
      -- so a new language automatically gets its icon.
      local function ext_group(label, exts, icon)
        local set = {}
        for _, e in ipairs(exts) do
          set[e] = true
        end
        if not icon then
          local devicons = require "nvim-web-devicons"
          icon = devicons.get_icon("file." .. exts[1], exts[1], {
            default = true,
          })
        end
        return {
          name = icon and (icon .. " " .. label) or label,
          matcher = function(buf)
            local ext = vim.api.nvim_buf_get_name(buf.id):match "%.([^./]+)$"
            return ext ~= nil and set[ext] == true
          end,
        }
      end

      -- Add a language: one line here. Third element pins an icon; omit it to
      -- auto-derive one from nvim-web-devicons.
      local ext_groups = {
        { "Infra", { "tf" } },
        { "Configs", { "yaml", "yml" } },
        { "Go", { "go" } },
        { "Python", { "py" } },
        { "Bash", { "sh" } },
        { "Lua", { "lua" } },
      }

      -- Groups that key off something other than a file extension stay
      -- hand-written; the extension-based ones are generated below.
      local group_items = {
        {
          name = " PRs",
          matcher = function(buf)
            return vim.api.nvim_get_option_value("filetype", {
              buf = buf.id,
            }) == "octo"
          end,
        },
        {
          name = " Brain",
          matcher = function(buf)
            return vim.api.nvim_buf_get_name(buf.id):match "%.md$"
              and is_brain(buf.id)
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
      }
      for _, g in ipairs(ext_groups) do
        table.insert(group_items, ext_group(g[1], g[2], g[3]))
      end

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
            items = group_items,
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
      "justinhj/battery.nvim",
    },
    event = "UIEnter",
    config = function(_, opts)
      -- Both shell out to macOS-only binaries (`obsidian` from Homebrew,
      -- `ipconfig getsummary`), so skip their polling timers elsewhere.
      if is_mac then
        local pomodoro = optional "config.obsidian.pomodoro"
        if pomodoro then
          pomodoro.setup()
        end
        local wifi = optional "config.wifi"
        if wifi then
          wifi.setup { update_rate_seconds = 30 }
        end
      end
      require("battery").setup { update_rate_seconds = 30 }
      require("lualine").setup(opts)
    end,
    opts = {
      options = {
        globalstatus = true,
      },
      sections = {
        lualine_z = {
          "location",
          {
            function()
              local segments = {}
              if is_mac then
                segments[#segments + 1] = require("config.wifi").statusline()
                  or ""
              end
              segments[#segments + 1] = require("battery").get_status_line()
                or ""
              segments[#segments + 1] = os.date "%H:%M"
              local parts = {}
              for _, seg in ipairs(segments) do
                seg = vim.trim(seg)
                if seg ~= "" then
                  parts[#parts + 1] = seg
                end
              end
              return table.concat(parts, "   ")
            end,
          },
        },
        lualine_x = {
          "codecompanion",
          {
            function()
              local pomodoro = optional "config.obsidian.pomodoro"
              return pomodoro and pomodoro.statusline() or ""
            end,
            cond = function()
              if not is_mac then
                return false
              end
              local pomodoro = optional "config.obsidian.pomodoro"
              return pomodoro ~= nil and pomodoro.cache.status ~= "stopped"
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
          "typescript",
          "tsx",
        })
        :wait(300000)
    end,
    build = ":TSUpdate",
  },
}
