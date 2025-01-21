vim.api.nvim_create_user_command("LoadTestSuite", function()
  require("lazy").load { plugins = { "nvim-dap-ui", "neotest" } }
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

return {
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "mfussenegger/nvim-dap-python",
      "nvim-neotest/nvim-nio",
      "leoluz/nvim-dap-go",
    },
    cmd = {
      "DapNew",
      "DapContinue",
      "DapTerminate",
      "DapToggleBreakpoint",
      "DapStepOver",
      "DapStepInto",
      "DapStepOut",
    },
    config = function()
      require("dapui").setup()
      require "config.nvim-dap"
    end,
    version = "*",
  },
  {
    cmd = {
      "Neotest",
    },
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
      require "config.neotest"
    end,
  },
}
