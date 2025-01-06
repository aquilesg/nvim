-- Confrom Autocommands
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

-- Octo mapping
vim.api.nvim_create_autocmd("FileType", {
  pattern = "octo",
  callback = function()
    vim.keymap.set(
      "i",
      "@",
      "@<C-x><C-o>",
      { noremap = true, silent = true, buffer = true }
    )
    vim.keymap.set(
      "i",
      "#",
      "#<C-x><C-o>",
      { noremap = true, silent = true, buffer = true }
    )
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

-- Obsidian mappings
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
  { desc = "Create new note from template" }
)

map("n", "<leader>fr", "<cmd> GrugFar <CR>", { desc = "Find and Replace" })

-- Telescope mappings
map("n", "<leader>ff", custom.find_files, { desc = "File Search" })
map("n", "<leader>fw", custom.livegrep, { desc = "Word Search" })
map("n", "<leader>fb", custom.list_open_buffers, { desc = "Word Search" })
map("n", "<leader>fc", custom.list_git_changes, { desc = "Word Search" })

-- Toggle Terminal mapping
map(
  { "n", "t" },
  "<A-h>",
  '<cmd> ToggleTerm name="" <CR>',
  { desc = "Toggle terminal" }
)
map(
  "n",
  "<A-u>",
  '<cmd> TermExec cmd="aws-environment uat platform" name="UAT Terminal 󰵮"  <CR>',
  { desc = "Toggle UAT terminal" }
)
map(
  "n",
  "<A-p>",
  '<cmd> TermExec cmd="aws-environment production platform" name="Production Terminal " <CR>',
  { desc = "Toggle Production terminal" }
)
map(
  { "n", "t" },
  "<A-a>",
  "<cmd> ToggleTermToggleAll <CR>",
  { desc = "Toggle all terminals" }
)
map(
  { "n", "t" },
  "<A-s>",
  "<cmd> TermSelect <CR>",
  { desc = "Open terminal picker" }
)

function _G.set_terminal_keymaps()
  map("t", "<esc>", [[<C-\><C-n>]], { buffer = 0, desc = "Exit Terminal mode" })
  map("t", "jk", [[<C-\><C-n>]], { buffer = 0, desc = "Move direction" })
  map(
    "t",
    "<C-h>",
    [[<Cmd>wincmd h<CR>]],
    { buffer = 0, desc = "Move to left buffer" }
  )
  map(
    "t",
    "<C-j>",
    [[<Cmd>wincmd j<CR>]],
    { buffer = 0, desc = "Move to buffer below" }
  )
  map(
    "t",
    "<C-k>",
    [[<Cmd>wincmd k<CR>]],
    { buffer = 0, desc = "Move to buffer above" }
  )
  map(
    "t",
    "<C-l>",
    [[<Cmd>wincmd l<CR>]],
    { buffer = 0, desc = "Move to right buffer" }
  )
  map(
    "t",
    "<C-w>",
    [[<C-\><C-n><C-w>]],
    { buffer = 0, desc = "Move to buffer" }
  )
end

vim.cmd "autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()"

return {
  {
    "stevearc/conform.nvim",
    event = "LspAttach",
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
    event = "UIEnter",
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
      "ObsidianNewFromTemplate",
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
    event = "UIEnter",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
  },
  {
    "numToStr/Comment.nvim",
    event = "UIEnter",
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = {
      "ToggleTerm",
      "TermExec",
      "ToggleTermToggleAll",
    },
    config = function()
      map("v", "<leader>ts", function()
        require("toggleterm").send_lines_to_terminal(
          "single_line",
          true,
          { args = vim.v.count }
        )
      end)
      map("v", "<leader>tl", function()
        require("toggleterm").send_lines_to_terminal(
          "visual_lines",
          true,
          { args = vim.v.count }
        )
      end)
      map("v", "<leader>tv", function()
        require("toggleterm").send_lines_to_terminal(
          "visual_selection",
          true,
          { args = vim.v.count }
        )
      end)

      require("toggleterm").setup {
        direction = "horizontal",
      }
    end,
  },
  {
    "mistricky/codesnap.nvim",
    build = "make",
    cmd = { "CodeSnap", "CodeSnapSave", "CodeSnapASCII" },
    opts = {
      has_breadcrumbs = true,
      has_line_number = true,
      bg_theme = "peach",
      watermark = "",
    },
  },
}
