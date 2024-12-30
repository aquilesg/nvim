local custom = require "custom_functions"
vim.api.nvim_create_user_command(
  "LoadTestSuite",
  custom.load_test_suite,
  { desc = "Load test suite" }
)
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
      require "config.nvim-dap"
    end,
  },
  {
    "nvim-neotest/neotest",
    cmd = {
      "Neotest",
    },
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-go",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "jbyuki/one-small-step-for-vimkind",
    },
    config = function()
      require "config.neotest"
    end,
  },
}
