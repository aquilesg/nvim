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
          adapter = "cursor_cli",
        },
      },
      display = {
        action_palette = {
          width = 95,
          height = 10,
          provider = "telescope",
          opts = {
            show_preset_actions = true,
            show_preset_prompts = true,
            title = "CodeCompanion actions",
          },
        },
      },
    },
  },
}
