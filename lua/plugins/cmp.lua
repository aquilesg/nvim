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
      "rcarriga/cmp-dap",
      "epwalsh/obsidian.nvim",
      "mikavilpas/blink-ripgrep.nvim",
      "giuxtaposition/blink-cmp-copilot",
      "Kaiser-Yang/blink-cmp-git",
    },
    event = "LspAttach",
    version = "*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      appearance = {
        kind_icons = {
          Obsidian = " ",
          Obsidian_tags = "󰜢 ",
          Obsidian_new = "󰈔 ",
          RipGrep = "󱉶 ",
          Copilot = "󱚣 ",
          Git = "󰊢 ",
          Text = "󰗧",
          Method = "",
          Function = "󰊕",
          Constructor = "󰒓 ",

          Field = "",
          Variable = "󱃻 ",
          Property = "󰖷",

          Class = "󱡠",
          Interface = "󱡠",
          Struct = "󱡠",
          Module = "󰅩",

          Unit = "󰪚",
          Value = "󰦨",
          Enum = "󰦨",
          EnumMember = "󰦨",

          Keyword = "󰻾",
          Constant = "󰏿",

          Snippet = "",
          Color = "󰏘",
          File = "󰈔",
          Reference = "󰬲",
          Folder = "󰉋",
          Event = "󱐋",
          Operator = "󰪚",
          TypeParameter = "󰬛",
        },
      },
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
            return { "lsp", "path", "lazydev", "copilot" }
          elseif
            success
            and node
            and vim.tbl_contains(
              { "comment", "line_comment", "block_comment" },
              node:type()
            )
          then
            return {
              "buffer",
              "git",
              "ripgrep",
            }
          elseif
            vim.api
              .nvim_buf_get_name(0)
              :find("^" .. vim.fn.expand "~/Documents/Work/") ~= nil
          then
            return {
              "buffer",
              "path",
              "ripgrep",
              "obsidian",
              "obsidian_new",
              "obsidian_tags",
            }
          elseif vim.bo.filetype == "codecompanion" then
            return { "buffer", "codecompanion" }
          elseif
            vim.tbl_contains({ "gitcommit", "octo" }, vim.bo.filetype)
            and vim.fn.mode() ~= "c"
          then
            return { "buffer", "git", "path", "ripgrep" }
          elseif require("cmp_dap").is_dap_buffer() then
            return { "dap", "snippets", "buffer" }
          elseif vim.bo.filetype == "markdown" then
            return { "buffer", "path", "ripgrep", "git" }
          else
            return {
              "lsp",
              "snippets",
              "buffer",
              "path",
              "copilot",
            }
          end
        end,
        providers = {
          dap = { name = "dap", module = "blink.compat.source" },
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          ripgrep = {
            module = "blink-ripgrep",
            name = "Ripgrep",
            score_offset = -10,
            opts = {
              prefix_min_len = 5,
            },
            transform_items = function(_, items)
              local CompletionItemKind =
                require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "RipGrep"
              for _, item in ipairs(items) do
                item.kind = kind_idx
                item.labelDetails = {
                  description = "RipGrep",
                }
              end
              return items
            end,
          },
          obsidian = {
            name = "obsidian",
            module = "blink.compat.source",
            score_offset = 100,
            transform_items = function(_, items)
              local CompletionItemKind =
                require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Obsidian"
              for _, item in ipairs(items) do
                item.kind = kind_idx
                item.labelDetails = {
                  description = "Obsidan",
                }
              end
              return items
            end,
          },
          obsidian_new = {
            name = "obsidian_new",
            module = "blink.compat.source",
            score_offset = 100,
            transform_items = function(_, items)
              local CompletionItemKind =
                require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Obsidian_new"
              for _, item in ipairs(items) do
                item.kind = kind_idx
                item.labelDetails = {
                  description = "Obsidian",
                }
              end
              return items
            end,
          },
          obsidian_tags = {
            name = "obsidian_tags",
            module = "blink.compat.source",
            score_offset = 100,
            transform_items = function(_, items)
              local CompletionItemKind =
                require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Obsidian_tags"
              for _, item in ipairs(items) do
                item.kind = kind_idx
                item.labelDetails = {
                  description = "VaultTag",
                }
              end
              return items
            end,
          },
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            async = true,
            transform_items = function(_, items)
              local CompletionItemKind =
                require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Copilot"
              for _, item in ipairs(items) do
                item.kind = kind_idx
              end
              return items
            end,
          },
          git = {
            module = "blink-cmp-git",
            async = true,
            score_offset = -10,
            name = "Git",
            opts = {
              use_items_pre_cache = false,
            },
            transform_items = function(_, items)
              local CompletionItemKind =
                require("blink.cmp.types").CompletionItemKind
              local kind_idx = #CompletionItemKind + 1
              CompletionItemKind[kind_idx] = "Git"
              for _, item in ipairs(items) do
                item.kind = kind_idx
              end
              return items
            end,
          },
        },
      },
    },
  },
}
