vim.api.nvim_create_user_command("LoadTestSuite", function()
  require("lazy").load { plugins = { "nvim-dap", "neotest" } }
  local dap, dv = require "dap", require "dap-view"
  dap.listeners.before.attach["dap-view-config"] = function()
    dv.open()
  end
  dap.listeners.before.launch["dap-view-config"] = function()
    dv.open()
  end
  dap.listeners.before.event_terminated["dap-view-config"] = function()
    dv.close()
  end
  dap.listeners.before.event_exited["dap-view-config"] = function()
    dv.close()
  end

  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "dap-view", "dap-view-term", "dap-repl" },
    callback = function(evt)
      vim.keymap.set("n", "q", "<C-w>q", { silent = true, buffer = evt.buf })
    end,
  })
end, { desc = "Load test suite" })

vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "Neotest Summary*",
  callback = function(ev)
    vim.keymap.set("n", "q", ":bdelete<CR>", {
      buffer = ev.buf,
      silent = true,
      desc = "Close neotest summary",
    })
  end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "neotest*",
  callback = function(ev)
    vim.keymap.set("n", "q", ":bdelete<CR>", {
      buffer = ev.buf,
      silent = true,
      desc = "Close neotest window",
    })
  end,
})

return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      {
        "leoluz/nvim-dap-go",
        opts = {
          delve = {
            initialize_timeout_sec = 45,
          },
        },
      },
      "mfussenegger/nvim-dap-python",
      {
        "igorlfs/nvim-dap-view",
        opts = {
          windows = {
            terminal = {
              hide = { "go" },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Dap Continue",
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
              vim.ui.input(
                { prompt = "Hit condition: " },
                function(hit_condition)
                  vim.ui.input(
                    { prompt = "Log message: " },
                    function(log_message)
                      require("dap").set_breakpoint(
                        condition ~= "" and condition or nil,
                        hit_condition ~= "" and hit_condition or nil,
                        log_message ~= "" and log_message or nil
                      )
                    end
                  )
                end
              )
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
          require("dap-view").toggle()
        end,
        desc = "Toggle Dap View",
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
          require "neotest-go" {},
        },
      }
    end,
  },
  keys = {
    {
      "<leader>ns",
      "<cmd> Neotest summary <CR>",
      desc = "Neotest Open Summary",
    },
    {
      "<leader>nr",
      function()
        require("neotest").run.run()
      end,
      desc = "Neotest Run nearest test",
    },
    {
      "<leader>nw",
      function()
        require("neotest").watch.watch()
      end,
      desc = "Neotest watch test",
    },
    {
      "<leader>ns",
      function()
        require("neotest").output.open { enter = true }
      end,
      desc = "Neotest open oputput",
    },
    {
      "<leader>ns",
      function()
        require("neotest").run.run { strategy = "dap" }
      end,
      desc = "Neotest debug nearest test",
    },
  },
}
