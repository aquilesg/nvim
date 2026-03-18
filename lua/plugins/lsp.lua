local ensure_installed_local = {
  "bash-language-server",
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
  "jedi-language-server",
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

local function on_attach(_, _)
  local map = vim.keymap.set
  map("n", "K", "<cmd> Lspsaga hover_doc <CR>", { desc = "Show hover doc" })
  map("n", "gr", "<cmd> Lspsaga finder <CR>", { desc = "Find references" })
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
  map("n", "<leader>ra", "<cmd> Lspsaga rename <CR>", { desc = "Lsp outline" })
  map(
    "n",
    "ca",
    "<cmd> Lspsaga code_action <CR>",
    { desc = "Show code actions" }
  )
end

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
    "**/playbooks/**/*.yaml",
    "*/roles/*.yaml",
    "*/inventory/*.yaml",
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
      local opts = {
        on_attach = on_attach,
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
          },
        },
      })
      vim.lsp.config("dockerls", {
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          on_attach()
        end,
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
    "scalameta/nvim-metals",
    ft = { "scala", "sbt" },
    opts = function()
      local metals_config = require("metals").bare_config()
      metals_config.init_options.statusBarProvider = "off"
      metals_config.settings = {
        serverVersion = "0.11.12",
      }

      metals_config.on_attach = function()
        require("metals").setup_dap()
        require("dap").configurations.scala = {
          {
            type = "scala",
            request = "launch",
            name = "Run or Test Target",
            metals = {
              runType = "runOrTestFile",
            },
          },
          {
            type = "scala",
            request = "launch",
            name = "Test Target",
            metals = {
              runType = "testTarget",
            },
          },
          {
            type = "scala",
            request = "attach",
            name = "Attach to Localhost",
            hostName = "localhost",
            port = 5005,
            buildTarget = "root",
          },
        }
        on_attach()
      end
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
  {
    "dgagn/diagflow.nvim",
    event = "LspAttach",
    opts = {},
  },
}
