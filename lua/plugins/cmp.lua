local is_brain = require("config.obsidian.vault").is_in_brain

-- register the Kitty kind once, so the enum doesn't grow on every completion
local kitty_kind_idx
local function kitty_kind()
  if not kitty_kind_idx then
    local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
    kitty_kind_idx = #CompletionItemKind + 1
    CompletionItemKind[kitty_kind_idx] = "Kitty"
  end
  return kitty_kind_idx
end

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
      "garyhurtz/blink_cmp_kitty",
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
          Kitty = "󰄛 ",
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
              "kitty",
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
              }
            end
          elseif
            vim.tbl_contains({ "gitcommit", "octo" }, vim.bo.filetype)
            and vim.fn.mode() ~= "c"
          then
            return { "buffer", "git", "path", "ripgrep", "kitty" }
          else
            return {
              "lsp",
              "snippets",
              "buffer",
              "path",
              "kitty",
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
          kitty = {
            module = "blink_cmp_kitty",
            name = "Kitty",
            score_offset = -12,
            opts = {
              -- period is multiplied by 1000 internally, so this is ~10s
              min_update_restart_period = 0.01,
              completion_item_lifetime = 60,
              -- skip other nvim windows: get-text returns rendered UI, not text
              include_window = function(ctx)
                if ctx.is_self then
                  return false
                end
                for _, proc in ipairs(ctx.foreground_processes or {}) do
                  for _, arg in ipairs(proc.cmdline or {}) do
                    if arg:match("n?vim$") then
                      return false
                    end
                  end
                end
                return true
              end,
            },
            transform_items = function(_, items)
              local kind = kitty_kind()
              for _, item in ipairs(items) do
                item.kind = kind
                item.labelDetails = { description = "Kitty" }
              end
              return items
            end,
          },
        },
      },
    },
  },
}
