return {
  {
    "miroshQa/debugmaster.nvim",
    dependencies = {
      "mfussenegger/nvim-dap",
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
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-go",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "jbyuki/one-small-step-for-vimkind",
    },
    ft = { "python", "go" },
    version = "*",
    config = function()
      require("neotest").setup {
        log_level = vim.log.levels.DEBUG,
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            args = { "--log-level", "DEBUG", "-vv" },
          }),
          require("neotest-go")({
            dap = {
              args = { "-gcflags=all=-N -l" },
            },
            experimental = {
              test_table = true,
            },
            args = { "-v", "-race", "-count=1" },
          }),
        },
      }

      -- Setup commands to make quitting easier
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neotest-summary",
        callback = function(ev)
          vim.keymap.set("n", "q", function()
            require("neotest").summary.toggle()
          end, {
            buffer = ev.buf,
            silent = true,
            desc = "Close neotest summary",
          })
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neotest-output",
        callback = function(ev)
          vim.keymap.set("n", "q", ":bdelete!<CR>", {
            buffer = ev.buf,
            silent = true,
            desc = "Close neotest output",
          })
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neotest-output-panel",
        callback = function(ev)
          vim.keymap.set("n", "q", ":bdelete!<CR>", {
            buffer = ev.buf,
            silent = true,
            desc = "Close neotest output",
          })
        end,
      })
    end,
    keys = {
      {
        "<leader>nr",
        function()
          local neotest = require("neotest")
          local pos = neotest.run.get_tree_from_args()
          if pos then
            neotest.run.run()
          else
            vim.notify("No test found at cursor position", vim.log.levels.WARN)
          end
        end,
        desc = "Neotest Run nearest test",
      },
      {
        "<leader>nF",
        function()
          require("neotest").run.run(vim.fn.expand "%")
        end,
        desc = "Neotest Run all tests in file",
      },
      {
        "<leader>nf",
        function()
          -- Get the function name under cursor and run it
          local neotest = require("neotest")
          local tree = neotest.run.get_tree_from_args()
          if tree then
            local pos = tree:data()
            -- If we're at a namespace/file, run the whole file
            if pos.type == "file" or pos.type == "dir" then
              neotest.run.run(vim.fn.expand "%")
            else
              -- Run the nearest test (function)
              neotest.run.run()
            end
          else
            vim.notify("No test found", vim.log.levels.WARN)
          end
        end,
        desc = "Neotest Run nearest test/file intelligently",
      },
      {
        "<leader>nd",
        function()
          require("neotest").run.run { strategy = "dap" }
        end,
        desc = "Neotest Debug nearest test",
      },
      {
        "<leader>nw",
        function()
          require("neotest").watch.watch()
        end,
        desc = "Neotest watch test",
      },
      {
        "<leader>no",
        function()
          require("neotest").output.open { enter = true }
        end,
        desc = "Neotest open oputput",
      },
      {
        "<leader>ns",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Neotest open summary",
      },
      {
        "<leader>nl",
        function()
          vim.cmd("edit " .. vim.fn.stdpath("log") .. "/neotest.log")
        end,
        desc = "Open neotest log",
      },
    },
  },
}
