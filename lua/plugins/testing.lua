vim.api.nvim_create_autocmd("FileType", {
  pattern = "neotest-summary",
  callback = function(ev)
    vim.keymap.set("n", "q", ":bdelete<CR>", {
      buffer = ev.buf,
      silent = true,
      desc = "Close neotest summary",
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "neotest-output",
  callback = function(ev)
    vim.keymap.set("n", "q", ":bdelete<CR>", {
      buffer = ev.buf,
      silent = true,
      desc = "Close neotest output",
    })
  end,
})

return {
  {
    "rcarriga/nvim-dap-ui",
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
    config = function()
      require("dapui").setup()
    end,
    keys = {
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Dap Continue / Start",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Dap Terminate",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Dap toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input(
            { prompt = "Breakpoint condition: " },
            function(condition)
              vim.ui.input({ prompt = "Hit count: " }, function(hit_condition)
                vim.ui.input({ prompt = "Log message: " }, function(log_message)
                  require("dap").set_breakpoint(
                    condition ~= "" and condition or nil,
                    hit_condition ~= "" and hit_condition or nil,
                    log_message ~= "" and log_message or nil
                  )
                end)
              end)
            end
          )
        end,
        desc = "Dap Set Conditional breakpoint",
      },
      {
        "<leader>dso",
        function()
          require("dap").step_over()
        end,
        desc = "Dap Step Over",
      },
      {
        "<leader>dsi",
        function()
          require("dap").step_into()
        end,
        desc = "dap step into",
      },
      {
        "<leader>dsO",
        function()
          require("dap").step_out()
        end,
        desc = "Dap Step Out",
      },
      {
        "<leader>dr",
        function()
          require("dap").restart()
        end,
        desc = "Dap Restart",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Dap run last",
      },
      {
        "<leader>dK",
        function()
          require("dap.ui.widgets").hover(nil, { border = "rounded" })
        end,
        desc = "Evaluate Value under cursor",
      },
      {
        "<leader>dP",
        function()
          local widgets = require "dap.ui.widgets"
          widgets.centered_float(widgets.scopes, { border = "rounded" })
        end,
        desc = "View Scopes",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "View Scopes",
      },
    },
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
