local ensure_installed = {
  "bash-language-server",
  "black",
  "buf",
  "clangd",
  "docker-compose-language-service",
  "dockerfile-language-server",
  "doctoc",
  "flake8",
  "gopls",
  "gofumpt",
  "google-java-format",
  "graphql-language-service-cli",
  "harper-ls",
  "html-lsp",
  "jdtls",
  "json-lsp",
  "lua-language-server",
  "markdownlint",
  "prettier",
  "pydocstyle",
  "pyright",
  "pylama",
  "ruff",
  "shellcheck",
  "shfmt",
  "terraform-ls",
  "tflint",
  "stylua",
  "sqlls",
  "typescript-language-server",
  "yaml-language-server",
}

vim.api.nvim_create_user_command("MasonInstallAll", function()
  vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
end, { desc = "Install All Mason Packages" })

-- Infrastructure as Code file detection
local autocmd = vim.api.nvim_create_autocmd

local terraform_group =
  vim.api.nvim_create_augroup("TerraformDetect", { clear = true })
local ansible_group =
  vim.api.nvim_create_augroup("AnsibleDetect", { clear = true })

-- Terraform related files
autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*.tf",
    "*.tfvars",
    "*.tfvars.json",
  },
  group = terraform_group,
  callback = function()
    vim.bo.filetype = "terraform"
  end,
})

autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*.hcl",
    ".terraformrc",
    "terraform.rc",
  },
  group = terraform_group,
  callback = function()
    vim.bo.filetype = "hcl"
  end,
})

autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*.tfstate",
    "*.tfstate.backup",
    "*.tfplan",
  },
  group = terraform_group,
  callback = function()
    vim.bo.filetype = "json"
  end,
})

-- Ansible related files
autocmd({ "BufRead", "BufNewFile" }, {
  pattern = {
    "*.yaml.ansible",
    "*/playbooks/*.yml",
    "*/roles/*.yml",
    "*/inventory/*.yml",
  },
  group = ansible_group,
  callback = function()
    vim.bo.filetype = "yaml.ansible"
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    event = "UIEnter",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    event = "UIEnter",
    opts = {},
    config = function()
      local on_attach = function()
        local map = vim.keymap.set
        map(
          "n",
          "K",
          "<cmd> Lspsaga hover_doc <CR>",
          { desc = "Show hover doc" }
        )
        map(
          "n",
          "gr",
          "<cmd> Lspsaga finder <CR>",
          { desc = "Find references" }
        )
        map(
          "n",
          "gd",
          "<cmd> Lspsaga goto_definition <CR>",
          { desc = "Go to definition" }
        )
        map(
          "n",
          "<leader>pd",
          "<cmd> Lspsaga peek_definition <CR>",
          { desc = "Peek definition" }
        )
        map(
          "n",
          "<leader>pD",
          "<cmd> Lspsaga peek_type_definition <CR>",
          { desc = "Peek type definition" }
        )
        map(
          "n",
          "<leader>ra",
          "<cmd> Lspsaga rename <CR>",
          { desc = "Lsp outline" }
        )
        map(
          "n",
          "ca",
          require("actions-preview").code_actions,
          { desc = "Show code actions" }
        )
      end

      local opts = {
        on_attach = on_attach,
        capabilities = require("blink.cmp").get_lsp_capabilities({}, true),
      }

      require("mason").setup()
      require("mason-lspconfig").setup()
      require("mason-lspconfig").setup_handlers {
        function(server_name)
          require("lspconfig")[server_name].setup(opts)
        end,
      }
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    cmd = {
      "Lspsaga",
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      lightbulb = {
        sign = false,
      },
    },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    opts = {
      preset = "ghost",
    },
  },
  {
    "aznhe21/actions-preview.nvim",
    event = "LspAttach",
    opts = {
      telescope = {
        sorting_strategy = "ascending",
        layout_strategy = "vertical",
        layout_config = {
          width = 0.8,
          height = 0.9,
          prompt_position = "top",
          preview_cutoff = 20,
          preview_height = function(_, _, max_lines)
            return max_lines - 15
          end,
        },
      },
    },
  },
  {
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    event = "LspAttach",
    opts = {
      excluded_lsp_clients = { "gopls", "pyright" },
    },
  },
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
      "giuxtaposition/blink-cmp-copilot",
      "rcarriga/cmp-dap",
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
            return { "buffer" }
          elseif vim.bo.filetype == "codecompanion" then
            return { "buffer", "codecompanion" }
          elseif vim.tbl_contains({ "gitcommit", "octo" }, vim.bo.filetype) then
            return { "buffer", "git", "path" }
          elseif require("cmp_dap").is_dap_buffer() then
            return { "dap", "snippets", "buffer" }
          else
            return { "lsp", "buffer", "path", "copilot" }
          end
        end,
        providers = {
          dap = { name = "dap", module = "blink.compat.source" },
          codecompanion = {
            name = "CodeCompanion",
            module = "codecompanion.providers.completion.blink",
          },
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            async = true,
          },
          git = { name = "git", module = "blink.compat.source" },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
    },
  },
}
