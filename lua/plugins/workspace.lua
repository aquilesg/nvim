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

-- Close Filetypes of a Buffer
vim.api.nvim_create_user_command("CloseFiletypeBuffers", function()
  local filetypes = {}
  for _, buf in ipairs(vim.fn.range(1, vim.fn.bufnr "$")) do
    -- Check if the buffer is valid and listed
    if vim.api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1 then
      local bufname = vim.fn.bufname(buf)
      if bufname ~= "" then
        local ft = vim.bo[buf].filetype
        if not vim.tbl_contains(filetypes, ft) then
          table.insert(filetypes, ft)
        end
      end
    end
  end

  local ft_message = "Available filetypes:\n"
  for i, ft in ipairs(filetypes) do
    ft_message = ft_message .. tostring(i) .. ": " .. ft .. "\n"
  end

  vim.notify(ft_message, vim.log.levels.INFO, {})

  local selected_num = tonumber(
    vim.fn.input "Enter the number corresponding to the filetype to close buffers: "
  )

  if selected_num == nil or selected_num < 1 or selected_num > #filetypes then
    print "Invalid selection"
    return
  end

  local selected_ft = filetypes[selected_num]

  for _, buf in ipairs(vim.fn.range(1, vim.fn.bufnr "$")) do
    -- Verify the buffer again before proceeding
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.fn.buflisted(buf) == 1
      and vim.bo[buf].filetype == selected_ft
    then
      vim.cmd("bdelete " .. buf)
    end
  end
end, {})

local map = vim.keymap.set
map("n", "<leader>fm", function()
  require("conform").format { async = true }
end, { desc = "Format document" })

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
        go = { "gofumpt" },
        python = { "black", "ruff" },
        bash = { "shfmt" },
        java = { "google-java-format" },
        javascript = { "prettier" },
        json = { "jq" },
        markdown = { "doctoc", "markdownlint" },
        typescript = { "ts-standard" },
        yaml = { "yamlfmt" },
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
    "MagicDuck/grug-far.nvim",
    keys = {
      {
        "<leader>fr",
        "<cmd> GrugFar <CR>",
        desc = "Find and Replace",
      },
    },

    opts = {},
  },
  {
    "Myzel394/easytables.nvim",
    cmd = { "EasyTablesCreateNew", "EasyTablesImportThisTable" },
    opts = {},
  },
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    opts = {},
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
    build = "./kitty/install-kittens.bash",
    event = "VeryLazy",
    keys = {
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
      },
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
      },
      {
        "<leader><leader>h",
        function()
          require("smart-splits").swap_buf_left()
        end,
      },
      {
        "<leader><leader>j",
        function()
          require("smart-splits").swap_buf_down()
        end,
      },
      {
        "<leader><leader>k",
        function()
          require("smart-splits").swap_buf_up()
        end,
      },
      {
        "<leader><leader>l",
        function()
          require("smart-splits").swap_buf_right()
        end,
      },
    },
  },
  {
    "shortcuts/no-neck-pain.nvim",
    keys = {
      {
        "<leader>4",
        function()
          require("no-neck-pain").toggle()
        end,
      },
    },
    opts = {
      width = 150,
    },
  },
  {
    "letieu/jira.nvim",
    opts = {},
    config = function()
      require("jira").setup {
        jira = {
          base = "https://includedhealth.atlassian.net",
          email = "aquiles.gomez@includedhealth.com",
          token = os.getenv "JIRA_API_TOKEN" or "",
          type = "basic",
          limit = 200,
        },
        queries = {
          ["My Tasks"] = "assignee = currentUser() AND resolution = Unresolved order by updated DESC",
        },

        projects = {
          ["CLOUD"] = {},
        },
      }
    end,
  },
}
