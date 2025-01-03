return {
  {
    "saghen/blink.compat",
    version = "*",
    opts = {},
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "petertriho/cmp-git",
      "rcarriga/cmp-dap",
      "epwalsh/obsidian.nvim",
    },
    event = "LspAttach",
    version = "*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        ["<CR>"] = {},
        ["<Tab>"] = {},
      },
      signature = { enabled = true },
      sources = {
        cmdline = {},
        default = function()
          local success, node = pcall(vim.treesitter.get_node)
          if vim.bo.filetype == "lua" then
            return { "lsp", "path", "copilot", "lazydev" }
          elseif
            (
              success
              and node
              and vim.tbl_contains(
                { "comment", "line_comment", "block_comment" },
                node:type()
              )
            ) or vim.bo.filetype == "markdown"
          then
            return { "obsidian", "obsidian_new", "obsidian_tags", "buffer" }
          elseif vim.bo.filetype == "codecompanion" then
            return { "buffer", "codecompanion" }
          elseif vim.tbl_contains({ "gitcommit", "octo" }, vim.bo.filetype) then
            return { "buffer", "git", "path" }
          elseif require("cmp_dap").is_dap_buffer() then
            return { "dap", "snippets", "buffer" }
          else
            return {
              "lsp",
              "snippets",
              "buffer",
              "path",
            }
          end
        end,
        providers = {
          dap = { name = "dap", module = "blink.compat.source" },
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
          },
          git = { name = "git", module = "blink.compat.source" },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          obsidian = {
            name = "obsidian",
            module = "blink.compat.source",
            score_offset = 100,
          },
          obsidian_new = {
            name = "obsidian_new",
            module = "blink.compat.source",
            score_offset = 100,
          },
          obsidian_tags = {
            name = "obsidian_tags",
            module = "blink.compat.source",
            score_offset = 100,
          },
        },
      },
    },
  },
}
