vim.cmd [[cab cc CodeCompanion]]
return {
  {
    keys = {
      {
        "<leader>a",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "Toggle CodeCompanion",
        mode = { "n", "v" },
      },
      {
        "ga",
        "<cmd>CodeCompanionChat Add<cr>",
        desc = "Open CodeCompanion Actions",
        mode = { "v" },
      },
    },
    "olimorris/codecompanion.nvim",
    opts = {
      strategies = {
        chat = {
          adapter = "copilot",
        },
        inline = {
          adapter = "copilot",
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_tools = true,
            show_server_tools_in_chat = true,
            add_mcp_prefix_to_tool_names = false,
            show_result_in_chat = true,
            format_tool = nil,
            make_vars = true,
            make_slash_commands = true,
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      {
        "ravitemer/mcphub.nvim",
        dependencies = {
          "nvim-lua/plenary.nvim",
        },
        build = "npm install -g mcp-hub@latest",
        config = function()
          require("mcphub").setup()
        end,
      },
    },
  },
}
