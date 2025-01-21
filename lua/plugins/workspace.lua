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

local map = vim.keymap.set
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

-- Toggle Terminal mapping
map(
  { "n", "t" },
  "<leader>tt",
  "<cmd> ToggleTerm <CR>",
  { desc = "Toggle terminal" }
)
map(
  "n",
  "<leader>tu",
  '<cmd> TermExec cmd="aws-environment uat platform" name="UAT Terminal 󰵮"  <CR>',
  { desc = "Toggle UAT terminal" }
)
map(
  "n",
  "<leader>tp",
  '<cmd> TermExec cmd="aws-environment production platform" name="Production Terminal " <CR>',
  { desc = "Toggle Production terminal" }
)
map(
  { "n", "t" },
  "<leader>ta",
  "<cmd> ToggleTermToggleAll <CR>",
  { desc = "Toggle all terminals" }
)
map(
  { "n", "t" },
  "<leader>ts",
  "<cmd> TermSelect <CR>",
  { desc = "Open terminal select" }
)

map("n", "<leader>is", function()
  local timestamp = tostring(os.date "- `%Y-%m-%d %H:%M:%S`")
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, { "" })
  vim.api.nvim_buf_set_text(0, row, 0, row, 0, { timestamp })
end, { desc = "Insert timestamp" })
map("n", "<leader>im", function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local disable = "<!-- markdownlint-disable-next-line -->"
  vim.api.nvim_buf_set_lines(0, line, line, false, { disable })
end, { desc = "Create disabled markdown lint section" })

function _G.set_terminal_keymaps()
  map("t", "<esc>", [[<C-\><C-n>]], { buffer = 0, desc = "Exit Terminal mode" })
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

local slow_format_filetypes = {
  "python",
  "json",
  "markdown",
}
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
        go = { "gofumpt", "golangci-lint" },
        python = { "black", "ruff" },
        bash = { "shfmt" },
        java = { "google-java-format" },
        json = { "jq" },
        markdown = { "doctoc", "markdownlint" },
        yaml = { "yamlfmt" },
      },
      formatters = {
        doctoc = {
          prepend_args = { "--update-only", "--github" },
        },
        golangci_lint = {
          command = "golangci-lint",
          args = {
            "run",
            "--fix",
            "--build-tags",
            "acceptance,server",
            "--enable",
            table.concat({
              "errcheck",
              "forbidigo",
              "gci",
              "gofmt",
              "goprintffuncname",
              "gosec",
              "gosimple",
              "govet",
              "ineffassign",
              "misspell",
              "nakedret",
              "noctx",
              "nolintlint",
              "revive",
              "staticcheck",
              "stylecheck",
              "typecheck",
              "unconvert",
              "unparam",
              "unused",
              "lll",
            }, ","),
            "--exclude-dirs",
            "(^|/)build($|/)",
            "--line-length=80",
          },
          stdin = true,
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
    opts = {
      pickers = {
        find_files = {
          theme = "dropdown",
        },
        live_grep = {
          theme = "dropdown",
        },
      },
    },
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
  {
    "mrjones2014/smart-splits.nvim",
    event = "UIEnter",
    config = function()
      -- Smart window resizing
      map("n", "<A-h>", require("smart-splits").resize_left)
      map("n", "<A-j>", require("smart-splits").resize_down)
      map("n", "<A-k>", require("smart-splits").resize_up)
      map("n", "<A-l>", require("smart-splits").resize_right)
      -- moving between splits
      map("n", "<C-h>", require("smart-splits").move_cursor_left)
      map("n", "<C-j>", require("smart-splits").move_cursor_down)
      map("n", "<C-k>", require("smart-splits").move_cursor_up)
      map("n", "<C-l>", require("smart-splits").move_cursor_right)
      map("n", "<C-\\>", require("smart-splits").move_cursor_previous)
      -- swapping buffers between windows
      map("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
      map("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
      map("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
      map("n", "<leader><leader>l", require("smart-splits").swap_buf_right)
    end,
  },
}
