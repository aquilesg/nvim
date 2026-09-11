-- Autocommand to close test windows
vim.api.nvim_create_autocmd("FileType", {
  pattern = "neotest*",
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
  end,
})
return {
  {
    "miroshQa/debugmaster.nvim",
    dependencies = {
      {
        "mfussenegger/nvim-dap",
        config = function()
          -- neotest-jest emits a `pwa-node` strategy config for its dap run.
          require("dap").adapters["pwa-node"] = {
            type = "server",
            host = "127.0.0.1",
            port = "${port}",
            executable = {
              -- js-debug-adapter binds to `::1` unless given a host.
              command = "js-debug-adapter",
              args = { "${port}", "127.0.0.1" },
            },
          }
        end,
      },
      "nvim-neotest/nvim-nio",
      {
        "leoluz/nvim-dap-go",
        opts = {
          delve = {
            initialize_timeout_sec = 45,
          },
          dap_configurations = {
            {
              type = "go",
              name = "Debug (Build Flags)",
              request = "launch",
              program = "${file}",
              buildFlags = function()
                return require("dap-go").get_build_flags()
              end,
            },
            {
              type = "go",
              name = "Attach to Running Delve server",
              request = "attach",
              mode = "remote",
              host = "localhost",
              port = 2345,
            },
          },
        },
      },
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          local cwd = vim.fn.getcwd()
          local venv_paths =
            { cwd .. "/venv/bin/python", cwd .. "/.venv/bin/python" }
          local python_path = nil

          for _, path in ipairs(venv_paths) do
            if vim.fn.filereadable(path) == 1 then
              python_path = path
              break
            end
          end

          if python_path then
            require("dap-python").setup(python_path)
          else
            require("dap-python").setup "python"
          end
        end,
      },
    },
    keys = {
      {
        "<leader>d",
        function()
          require("debugmaster").mode.toggle()
        end,
        desc = "Start Debug mode",
      },
    },
    on_attach = function()
      vim.keymap.set(
        "t",
        "<C-\\>",
        "<C-\\><C-n>",
        { desc = "Exit terminal mode" }
      )
    end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-plenary",
      "nvim-neotest/neotest-vim-test",
      {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
      },
      {
        "fredrikaverpil/neotest-golang",
        version = "*",
        dependencies = {
          {
            "leoluz/nvim-dap-go",
          },
        },
      },
      {
        "nvim-neotest/neotest-python",
      },
      {
        "nvim-neotest/neotest-jest",
      },
      {
        "marilari88/neotest-vitest",
      },
      {
        "thenbe/neotest-playwright",
        dependencies = { "nvim-telescope/telescope.nvim" },
      },
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-golang"] = {
        go_test_args = {
          "-v",
          "-race",
        },
      }
      opts.adapters["neotest-python"] = {
        python = function()
          local cwd = vim.fn.getcwd()
          local venv_paths =
            { cwd .. "/venv/bin/python", cwd .. "/.venv/bin/python" }
          local python_path = nil

          for _, path in ipairs(venv_paths) do
            if vim.fn.filereadable(path) == 1 then
              python_path = path
              break
            end
          end
          return python_path
        end,
      }
      opts.adapters["neotest-jest"] = {
        -- Jest sharding across workers loses breakpoints, so debug in-process.
        strategy_config = function(config)
          if config.type == "pwa-node" then
            table.insert(config.args, "--runInBand")
            config.skipFiles = { "<node_internals>/**", "**/node_modules/**" }
          end
          return config
        end,
      }

      local function dap_strategy(command, cwd)
        return {
          name = "Debug Test",
          type = "pwa-node",
          request = "launch",
          runtimeExecutable = command[1],
          args = { unpack(command, 2) },
          cwd = cwd or "${workspaceFolder}",
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
        }
      end

      -- Runners that fork workers lose breakpoints, so dap runs get forced
      -- single-process and the strategy is rebuilt from the final command.
      local function debuggable(adapter, dap_args)
        local build_spec = adapter.build_spec
        adapter.build_spec = function(args)
          local spec = build_spec(args)
          if spec and args.strategy == "dap" then
            vim.list_extend(spec.command, dap_args)
            spec.strategy = dap_strategy(spec.command, spec.cwd)
          end
          return spec
        end
        return adapter
      end

      -- Both JS adapters match `.spec.*` by default and would claim the same
      -- files, so playwright takes `.spec.*` and vitest keeps the rest.
      local function is_spec_file(file)
        return file:match "%.spec%.[jt]sx?$" ~= nil
      end

      local vitest = require "neotest-vitest"
      opts.adapters[#opts.adapters + 1] = debuggable(
        vitest {
          is_test_file = function(file)
            if file:match "__tests__" or file:match "%.test%.[jt]sx?$" then
              return true
            end
            local playwright_config = vim.fs.root(
              file,
              { "playwright.config.ts", "playwright.config.js" }
            )
            return is_spec_file(file) and playwright_config == nil
          end,
        },
        { "--no-file-parallelism" }
      )

      local playwright = require "neotest-playwright"
      opts.adapters[#opts.adapters + 1] = debuggable(
        playwright.adapter {
          options = {
            is_test_file = is_spec_file,
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        },
        { "--workers=1", "--timeout=0" }
      )
    end,
    config = function(_, opts)
      if opts.adapters then
        local adapters = {}
        for name, config in pairs(opts.adapters or {}) do
          if type(name) == "number" then
            if type(config) == "string" then
              config = require(config)
            end
            adapters[#adapters + 1] = config
          elseif config ~= false then
            local adapter = require(name)
            if type(config) == "table" and not vim.tbl_isempty(config) then
              local meta = getmetatable(adapter)
              if adapter.setup then
                adapter.setup(config)
              elseif adapter.adapter then
                adapter.adapter(config)
                adapter = adapter.adapter
              elseif meta and meta.__call then
                adapter(config)
              else
                error("Adapter " .. name .. " does not support setup")
              end
            end
            adapters[#adapters + 1] = adapter
          end
        end
        opts.adapters = adapters
      end

      require("neotest").setup(opts)
    end,
    keys = {
      {
        "<leader>na",
        function()
          require("neotest").run.attach()
        end,
        desc = "[n]eotest [a]ttach",
      },
      {
        "<leader>nf",
        function()
          require("neotest").run.run(vim.fn.expand "%")
        end,
        desc = "[n]eotest run [f]ile",
      },
      {
        "<leader>nA",
        function()
          require("neotest").run.run(vim.uv.cwd())
        end,
        desc = "[n]eotest [A]ll files",
      },
      {
        "<leader>nS",
        function()
          require("neotest").run.run { suite = true }
        end,
        desc = "[n]eotest [S]uite",
      },
      {
        "<leader>nn",
        function()
          require("neotest").run.run()
        end,
        desc = "[n]eotest [n]earest",
      },
      {
        "<leader>nl",
        function()
          require("neotest").run.run_last()
        end,
        desc = "[n]eotest [l]ast",
      },
      {
        "<leader>ns",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "[n]eotest [s]ummary",
      },
      {
        "<leader>no",
        function()
          require("neotest").output.open { enter = true, auto_close = true }
        end,
        desc = "[n]eotest [o]utput",
      },
      {
        "<leader>nO",
        function()
          require("neotest").output_panel.toggle()
        end,
        desc = "[n]eotest [O]utput panel",
      },
      {
        "<leader>nt",
        function()
          require("neotest").run.stop()
        end,
        desc = "[n]eotest [t]erminate",
      },
      {
        "<leader>nd",
        function()
          require("neotest").run.run { suite = false, strategy = "dap" }
        end,
        desc = "[n]eotest debug nearest test",
      },
      {
        "<leader>nD",
        function()
          require("neotest").run.run { vim.fn.expand "%", strategy = "dap" }
        end,
        desc = "[n]eotest debug current file",
      },
    },
  },
}
