-- Close Filetypes of a Buffer
local is_in_brain = require("config.obsidian.vault").is_in_brain

-- Effective filetype for the command: brain-vault markdown notes are grouped
-- under a synthetic "brain" filetype so they can be listed/closed separately.
local function effective_filetype(buf)
  local ft = vim.bo[buf].filetype
  if ft == "markdown" and is_in_brain(buf) then
    return "brain"
  end
  return ft
end

vim.api.nvim_create_user_command("CloseFiletypeBuffers", function()
  local filetypes = {}
  for _, buf in ipairs(vim.fn.range(1, vim.fn.bufnr "$")) do
    -- Check if the buffer is valid and listed
    if vim.api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1 then
      local bufname = vim.fn.bufname(buf)
      if bufname ~= "" then
        local ft = effective_filetype(buf)
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
      and effective_filetype(buf) == selected_ft
    then
      vim.cmd("bdelete " .. buf)
    end
  end
end, {})

local map = vim.keymap.set
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
  python = true,
  json = true,
  markdown = true,
}

local function autoformat_disabled(bufnr)
  return vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format { async = true, bufnr = 0 }
        end,
        desc = "Format document",
      },
    },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
      format_on_save = function(bufnr)
        if autoformat_disabled(bufnr) then
          return
        end
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
        if autoformat_disabled(bufnr) then
          return
        end
        if not slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return { lsp_format = "fallback" }
      end,

      formatters_by_ft = {
        lua = { "stylua" },
        go = { "gofumpt" },
        python = { "ruff_organize_imports", "ruff_format" },
        bash = { "shfmt" },
        java = { "google-java-format" },
        kotlin = { "ktlint" },
        swift = { "swiftformat" },
        javascript = { "prettier" },
        json = { "jq" },
        jsonc = { "prettier" },
        markdown = { "doctoc", "markdownlint" },
        typescript = { "ts-standard" },
        yaml = { "yamlfmt" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        graphql = { "prettier" },
        sql = { "sqlfluff" },
        toml = { "taplo" },
        xml = { "xmlformatter" },
        terraform = { "terraform_fmt" },
        hcl = { "terraform_fmt" },
        rust = { "rustfmt", lsp_format = "fallback" },
      },
      formatters = {
        doctoc = {
          prepend_args = { "--update-only", "--github" },
        },
      },
    },
    config = function(_, opts)
      require("conform").setup(opts)

      -- Fenced code-block languages -> vim filetypes conform knows about.
      local ft_aliases = {
        js = "javascript",
        ts = "typescript",
        py = "python",
        sh = "bash",
        shell = "bash",
        zsh = "bash",
        yml = "yaml",
        md = "markdown",
        tf = "terraform",
        gql = "graphql",
        rs = "rust",
        kt = "kotlin",
        postgres = "sql",
        psql = "sql",
        mysql = "sql",
      }

      -- Language of the fenced code block enclosing `lnum`, or nil if not in one.
      local function detect_fence_lang(bufnr, lnum)
        for i = lnum, 1, -1 do
          local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, true)[1]
          local lang = line:match "^%s*```([%w_%-%.]+)"
          if lang then
            return ft_aliases[lang] or lang
          end
          -- A bare ``` above us is a closing fence => we're not inside a block.
          if line:match "^%s*```%s*$" then
            return nil
          end
        end
        return nil
      end

      -- Format lines [line1, line2] of the current buffer as `filetype`,
      -- reusing the conform formatters configured for that filetype. Runs in a
      -- scratch buffer so range-unaware formatters (jq, etc.) see only the
      -- selection. Strips surrounding ``` fences if they were included.
      local function format_range_as(filetype, line1, line2)
        local start_idx, end_idx = line1 - 1, line2
        local lines = vim.api.nvim_buf_get_lines(0, start_idx, end_idx, false)
        if
          #lines >= 2
          and lines[1]:match "^%s*```"
          and lines[#lines]:match "^%s*```"
        then
          start_idx = start_idx + 1
          end_idx = end_idx - 1
          lines = vim.api.nvim_buf_get_lines(0, start_idx, end_idx, false)
        end

        local scratch = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
        vim.bo[scratch].filetype = filetype
        local ok = require("conform").format {
          bufnr = scratch,
          async = false,
          quiet = true,
          lsp_format = "never",
          timeout_ms = 3000,
        }
        if ok then
          local formatted = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
          vim.api.nvim_buf_set_lines(0, start_idx, end_idx, false, formatted)
        else
          vim.notify(
            "Format: no formatter for '" .. filetype .. "'",
            vim.log.levels.WARN
          )
        end
        vim.api.nvim_buf_delete(scratch, { force = true })
      end

      vim.api.nvim_create_user_command("Format", function(args)
        local has_range = args.count ~= -1

        -- In markdown, format a selection inside a code fence as its language.
        if has_range and vim.bo.filetype == "markdown" then
          local lang = detect_fence_lang(0, args.line1)
          if lang then
            format_range_as(lang, args.line1, args.line2)
            return
          end
        end

        local range = nil
        if has_range then
          local end_line =
            vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        require("conform").format {
          async = true,
          bufnr = 0,
          lsp_format = "fallback",
          range = range,
        }
      end, { range = true })

      -- Explicitly format a selection as a given filetype, e.g. :'<,'>FormatAs json
      vim.api.nvim_create_user_command("FormatAs", function(args)
        local filetype = ft_aliases[args.args] or args.args
        format_range_as(filetype, args.line1, args.line2)
      end, {
        range = true,
        nargs = 1,
        complete = function(arglead)
          local fts = vim.tbl_keys(opts.formatters_by_ft)
          table.sort(fts)
          return vim.tbl_filter(function(ft)
            return ft:find(arglead, 1, true) == 1
          end, fts)
        end,
      })

      vim.api.nvim_create_user_command("FormatDisable", function()
        vim.b.disable_autoformat = true
      end, {
        desc = "Disable autoformat-on-save for buffer",
        bang = true,
      })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
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
        desc = "Trigger No Neck Pain",
      },
    },
    opts = {
      width = 150,
    },
  },
  {
    "letieu/jira.nvim",
    enabled = (os.getenv "JIRA_API_TOKEN" or "") ~= "",
    opts = {},
    config = function()
      require("jira").setup {
        jira = {
          base = "https://includedhealth.atlassian.net",
          email = "aquiles.gomez@includedhealth.com",
          token = os.getenv "JIRA_API_TOKEN" or "",
          type = "basic",
          limit = 20,
        },
        active_sprint_query = [[
          project = CLOUD
          AND status NOT IN (Completed, Done, "Won't Do", Backlog, "In Sprint/Up Next")
          AND sprint != empty
          AND "eng pod[labels]" IN (cloud-observability, cloud-platform-infrastructure-risk-pod, cloud-data, cloud-resiliency, cloud-containerization, cloud-platform-operational-risk-pod) ORDER BY created DESC
        ]],
        queries = {
          ["On Call Tickets"] = [[ 
            labels IN (cloud-platform-triage-need-sort, cloud-platform-triage-documentation, cloud-platform-triage-ongoing-issue, cloud-platform-triage-bug, cloud-platform-triage-feature-request, cloud-platform-triage-other)
            AND project = CLOUD 
            AND created >= -1w ORDER BY created DESC 
          ]],
          ["Created By Me Within Last Week"] = [[
            reporter = currentUser() 
            AND created >= -1w ORDER BY created DESC 
          ]],
          ["Created By Me Unresolved"] = [[
            reporter = currentUser() 
            AND resolution = Unresolved ORDER BY created DESC 
            ]],
        },

        projects = {
          ["CLOUD"] = {},
        },
      }
    end,
    keys = {
      {
        "<leader>jt",
        "<cmd> Jira Cloud <CR>",
        desc = "Open Jira Tickets",
      },
    },
  },
  {
    event = "VeryLazy",
    "stevearc/resession.nvim",
    opts = {},
    keys = {
      {
        "<leader>ss",
        function()
          local resession = require "resession"
          local bufnr = vim.api.nvim_get_current_buf()
          local clients = vim.lsp.get_clients { bufnr = bufnr }

          for _, client in ipairs(clients) do
            vim.lsp.stop_client(client.id, true)
          end

          resession.save()
        end,
        desc = "Save Session",
      },
      {
        "<leader>sl",
        function()
          local resession = require "resession"
          resession.load()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if
              vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted
            then
              vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })
            end
          end
        end,
        desc = "Load Session",
      },
      {
        "<leader>sd",
        function()
          local resession = require "resession"
          resession.delete()
        end,
        desc = "Delete Session",
      },
    },
  },
}
