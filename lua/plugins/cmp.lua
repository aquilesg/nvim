local is_brain = require("config.custom_func").is_in_brain
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
      "obsidian.nvim/obsidian.nvim",
      "mikavilpas/blink-ripgrep.nvim",
      "fang2hou/blink-copilot",
      "archie-judd/blink-cmp-words",
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
      cmdline = { enabled = false },
      sources = {
        default = function()
          local success, node = pcall(vim.treesitter.get_node)
          if vim.bo.filetype == "lua" then
            return { "lsp", "path", "lazydev", "copilot" }
          elseif
            success
            and node
            and vim.tbl_contains({
              "comment",
              "line_comment",
              "block_comment",
              "dictionary",
              "thesaurus",
            }, node:type())
          then
            return {
              "buffer",
              "git",
              "ripgrep",
            }
          elseif is_brain(0) then
            -- Check if we're in a code block
            local success, node = pcall(vim.treesitter.get_node)
            if success and node and node:type() == "code_fence_content" then
              return {
                "buffer",
                "snippets",
                "path",
                "ripgrep",
                "path",
                "copilot",
                "dictionary",
                "thesaurus",
              }
            else
              return {
                "buffer",
                "path",
                "ripgrep",
                "obsidian",
                "obsidian_new",
                "obsidian_tags",
                "dictionary",
                "thesaurus",
              }
            end
          elseif
            vim.tbl_contains({ "gitcommit", "octo" }, vim.bo.filetype)
            and vim.fn.mode() ~= "c"
          then
            return { "buffer", "git", "path", "ripgrep" }
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
          thesaurus = {
            name = "blink-cmp-words",
            score_offset = -20,
            module = "blink-cmp-words.thesaurus",
            opts = {},
          },
          dictionary = {
            name = "blink-cmp-words",
            score_offset = -20,
            module = "blink-cmp-words.dictionary",
            opts = {},
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
            score_offset = 10,
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
            score_offset = 10,
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
            score_offset = 10,
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
            module = "blink-copilot",
            score_offset = -10,
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
