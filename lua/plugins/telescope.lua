return {
  "nvim-telescope/telescope.nvim",
  opts = {
    pickers = {
      find_files = {
        theme = "dropdown",
      },
      live_grep = {
        theme = "dropdown",
      },
    },
  },
  event = "UIEnter",
  dependencies = {
    "nvim-telescope/telescope-live-grep-args.nvim",
  },
  keys = {
    {
      "<leader>fb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files {
          no_ignore = true,
        }
      end,
      desc = "Find Files",
    },
    {
      "<leader>fw",
      function()
        require("telescope").extensions.live_grep_args.live_grep_args()
      end,
      desc = "Find Words",
    },
    {
      "<leader>gs",
      function()
        require("telescope.builtin").git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gS",
      function()
        require("telescope.builtin").git_stash()
      end,
      desc = "Git Status",
    },
    {
      "<leader>vD",
      function()
        require("telescope.builtin").diagnostics {}
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>vd",
      function()
        require("telescope.builtin").diagnostics {
          bufnr = 0,
        }
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>go",
      function()
        require("telescope.builtin").lsp_document_symbols { show_line = true }
      end,
      desc = "LSP Symbols",
    },
  },
}
