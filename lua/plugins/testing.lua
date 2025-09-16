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
      "mfussenegger/nvim-dap-python",
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
    lazy = true,
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
    version = "*",
    config = function()
      require("neotest").setup {
        adapters = {
          require "neotest-python" {
            dap = { justMyCode = false },
          },
          require "neotest-go" {
            dap = {
              args = { "-gcflags=all=-N -l" },
            },
          },
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
          require("neotest").run.run()
        end,
        desc = "Neotest Run nearest test",
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
    },
  },
}
