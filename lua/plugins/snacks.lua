return {
  "folke/snacks.nvim",
  priority = 1000,
  keys = {
    {
      "<leader>gl",
      function()
        Snacks.lazygit.open()
      end,
      desc = "Open Lazy git",
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
