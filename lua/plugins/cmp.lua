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
      "mikavilpas/blink-ripgrep.nvim",
      "Kaiser-Yang/blink-cmp-git",
      "aquilesg/obsidian",
    },
    event = "LspAttach",
    version = "*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      appearance = {
        kind_icons = {
          RipGrep = "󱉶 ",
          Git = "󰊢 ",
        },
      },
      keymap = {
        ["<CR>"] = {},
        ["<Tab>"] = {},
      },
      signature = { enabled = true },
      cmdline = { enabled = true },
      sources = {
        default = function()
          local success, node = pcall(vim.treesitter.get_node)
          if vim.bo.filetype == "lua" then
            return { "lsp", "path", "lazydev" }
          elseif
            success
            and node
            and vim.tbl_contains({
              "comment",
              "line_comment",
              "block_comment",
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
                "lsp",
                "buffer",
                "snippets",
                "ripgrep",
                "path",
              }
            else
              return {
                "lsp",
                "buffer",
                "path",
                "ripgrep",
                "obsidian_wiki_links",
                "obsidian_tags_body",
                "obsidian_tags_frontmatter",
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
            }
          end
        end,
        providers = {
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
              prefix_min_len = 2,
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
          obsidian_tags_body = {
            name = "Obsidian (body)",
            module = "obsidian.cmp.tags_body",
            opts = {},
          },
          obsidian_tags_frontmatter = {
            name = "Obsidian (FM)",
            module = "obsidian.cmp.tags_frontmatter",
            opts = {},
          },
          obsidian_wiki_links = {
            name = "Obsidian (wiki)",
            module = "obsidian.cmp.wiki_links",
            score_offset = 4,
            opts = {},
          },
        },
      },
    },
  },
}
