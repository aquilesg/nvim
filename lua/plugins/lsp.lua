local ensure_installed_local = {
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
  "marksman",
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
  local registry = require "mason-registry"
  for _, pkg in ipairs(ensure_installed_local) do
    if not registry.is_installed(pkg) then
      vim.cmd("MasonInstall " .. pkg)
    end
  end
end, {})

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
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      { "neovim/nvim-lspconfig" },
    },
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
    config = function()
      local on_attach = function(_, _)
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
      vim.lsp.config("*", opts)
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = {
              url = "https://platform-api.us-east-1.uat.grnds.com/api/json/catalog.json",
              enable = os.getenv "AWS_USERNAME" ~= nil,
            },
            ghDash = {
              url = "https://dlvhdr.github.io/gh-dash/configuration/gh-dash/schema.json",
            },
          },
        },
      })
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
  {
    "scalameta/nvim-metals",
    ft = { "scala", "sbt" },
    opts = function()
      local metals_config = require("metals").bare_config()
      metals_config.init_options.statusBarProvider = "off"
      metals_config.settings = {
        serverVersion = "0.11.12",
      }
      return metals_config
    end,
    config = function(self, metals_config)
      local nvim_metals_group =
        vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = self.ft,
        callback = function()
          require("metals").initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end,
  },
}
