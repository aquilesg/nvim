vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line =
      vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format {
    async = true,
    lsp_format = "fallback",
    range = range,
  }
end, { range = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    require("conform").format { async = true, lsp_fallback = true }
  end,
})

local slow_format_filetypes = {
  "autopep8",
  "autoflake",
  "black",
  "ruff",
  "json",
  "markdown",
}

local map = vim.keymap.set
local custom = require "custom_functions"
map("n", "<leader>fm", function()
  require("conform").format { async = true }
end, { desc = "Format document" })

map(
  "n",
  "<leader>ot",
  "<cmd> ObsidianToday <CR>",
  { desc = "Open today's note" }
)
map(
  "n",
  "<leader>ou",
  "<cmd> ObsidianTomorrow <CR>",
  { desc = "Open tomorrow's note" }
)
map(
  "n",
  "<leader>oy",
  "<cmd> ObsidianYesterday <CR>",
  { desc = "Open yesterday's note" }
)
map(
  "n",
  "<leader>osn",
  "<cmd> ObsidianSearch <CR>",
  { desc = "Obsidian search notes" }
)
map("n", "<leader>ost", "<cmd> ObsidianTags <CR>", { desc = "Search for tags" })
map(
  "n",
  "<leader>oq",
  "<cmd> ObsidianQuickSwitch <CR>",
  { desc = "Quick switch to different note" }
)
map(
  "n",
  "<leader>oo",
  "<cmd> ObsidianOpen <CR>",
  { desc = "Open current file in Obsidian" }
)
map(
  "n",
  "<leader>op",
  "<cmd> ObsidianPasteImg <CR>",
  { desc = "Paste image into Obsidian note" }
)
map(
  "n",
  "<leader>on",
  "<cmd> ObsidianNewFromTemplate <CR>",
  { desc = "Paste image into Obsidian note" }
)

map("n", "<leader>fr", "<cmd> GrugFar <CR>", { desc = "Find and Replace" })

map("n", "<leader>ff", custom.find_files, { desc = "File Search" })
map("n", "<leader>fw", custom.livegrep, { desc = "Word Search" })

return {
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
      format_on_save = function(bufnr)
        if slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        local function on_format(err)
          if err and err:match "timeout$" then
            slow_format_filetypes[vim.bo[bufnr].filetype] = true
          end
        end

        return { timeout_ms = 1000, lsp_format = "fallback" }, on_format
      end,

      format_after_save = function(bufnr)
        if not slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return { lsp_format = "fallback" }
      end,

      formatters_by_ft = {
        lua = { "stylua" },
        go = { "gofumpt" },
        python = { "black", "ruff" },
        bash = { "shfmt" },
        java = { "google-java-format" },
        json = { "jq" },
        markdown = { "doctoc", "markdownlint" },
      },
      formatters = {
        doctoc = {
          prepend_args = { "--update-only", "--github" },
        },
      },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },
  {
    "epwalsh/obsidian.nvim",
    event = "VeryLazy",
    cmd = {
      "ObsidianOpen",
      "ObsidianNew",
      "ObsidianQuickSwitch",
      "ObsidianToday",
      "ObsidianYesterday",
      "ObsidianWorkspace",
      "ObsidianTemplate",
      "ObsidianSearch",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "Work",
          path = "~/Documents/Work",
          overrides = {
            daily_notes = {
              folder = "DailyNotes",
              template = "daily.md",
            },
            templates = {
              subdir = "Templates",
              substitutions = {
                pretty_date = function()
                  return os.date "%B %d, %Y"
                end,
              },
            },
          },
        },
      },
      ui = {
        enable = false,
      },
      use_advanced_uri = true,
      suppress_missing_scope = {
        projects_v2 = true,
      },
      follow_url_func = function(url)
        vim.fn.jobstart { "open", url }
      end,
    },
  },
  {
    "MagicDuck/grug-far.nvim",
    cmd = {
      "GrugFar",
    },
    opts = {},
  },
  {
    "Myzel394/easytables.nvim",
    cmd = { "EasyTablesCreateNew", "EasyTablesImportThisTable" },
    opts = {},
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
  },
  {
    "numToStr/Comment.nvim",
    opts = {},
  },
}
