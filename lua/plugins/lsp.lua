local ensure_installed = {
  "bash-language-server",
  "basedpyright",
  "black",
  "buf",
  "clangd",
  "docker-compose-language-service",
  "dockerfile-language-server",
  "doctoc",
  "gopls",
  "gofumpt",
  "google-java-format",
  "graphql-language-service-cli",
  "harper-ls",
  "html-lsp",
  "jdtls",
  "jq",
  "json-lsp",
  "lua-language-server",
  "markdownlint",
  "prettier",
  "proselint",
  "ruff",
  "shellcheck",
  "shfmt",
  "terraform-ls",
  "tflint",
  "stylua",
  "sqlls",
  "typescript-language-server",
  "yaml-language-server",
  "yamlfmt",
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
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
    config = function()
      local on_attach = function(client, bufnr)
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
      { path = "snacks.nvim", words = { "Snacks" } },
      { path = "lazy.nvim", words = { "LazyVim" } },
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
    opts = {},
  },
}
