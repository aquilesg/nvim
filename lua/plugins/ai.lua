return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua", opts = {}, event = "LspAttach" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    opts = {},
    keys = {
      {
        "<leader>a",
        function()
          require("CopilotChat").toggle {
            auto_insert_mode = true,
          }
        end,
        desc = "Open Copilot Chat",
      },
    },
  },
}
