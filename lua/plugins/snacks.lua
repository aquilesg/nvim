return {
  "folke/snacks.nvim",
  priority = 1000,
  keys = {
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files {
          hidden = true,
          follow = true,
        }
      end,
      desc = "Find Files",
    },
    {
      "<leader>fw",
      function()
        Snacks.picker.grep {
          hidden = true,
          follow = true,
          buffers = false,
        }
      end,
      desc = "Find Words",
    },
    {
      "<leader>gL",
      function()
        Snacks.picker.git_log()
      end,
      desc = "Git Log",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>vd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>gl",
      function()
        Snacks.lazygit.open()
      end,
      desc = "Open Lazy git",
    },
    {
      "<leader>vm",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>vq",
      function()
        Snacks.picker.qflist()
      end,
      desc = "Quickfix List",
    },
    {
      "<leader>vc",
      function()
        Snacks.picker.todo_comments()
      end,
      desc = "Todo",
    },
    {
      "<leader>C",
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "Colorschemes",
    },
    {
      "<leader>go",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "LSP Symbols",
    },
  },
  opts = {
    picker = {},
    image = {},
    indent = {
      only_scope = true,
    },
    scroll = {},
    quickfile = { enabled = true },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        {
          icon = " ",
          title = "Keymaps",
          section = "keys",
          indent = 2,
          padding = 1,
        },
        {
          icon = " ",
          title = "Recent Files",
          section = "recent_files",
          indent = 2,
          padding = 1,
        },
        {
          icon = " ",
          title = "Projects",
          section = "projects",
          indent = 2,
          padding = 1,
        },
        { section = "startup" },
      },
    },
  },
  lazy = false,
}
