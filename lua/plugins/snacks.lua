return {
  "folke/snacks.nvim",
  priority = 1000,
  keys = {
    {
      "<leader>gl",
      function()
        require("snacks").lazygit.open()
      end,
      desc = "Open Lazy git",
    },
    {
      "<leader>C",
      function()
        require("snacks").picker.colorschemes()
      end,
      desc = "Colorschemes",
    },
    {
      "<leader>go",
      function()
        require("snacks").picker.lsp_symbols()
      end,
      desc = "LSP Symbols",
    },
    {
      "<leader>gp",
      function()
        Snacks.picker.gh_pr()
      end,
      desc = "GitHub Pull Requests (open)",
    },
    {
      "<leader>gP",
      function()
        Snacks.picker.gh_pr { state = "all" }
      end,
      desc = "GitHub Pull Requests (all)",
    },
  },
  opts = {
    image = {},
    indent = {
      only_scope = true,
      chunk = {
        enabled = true,
        only_current = true,
      },
    },
    scroll = {},
    gh = {},
    quickfile = { enabled = true },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        {
          pane = 2,
          icon = " ",
          desc = "Browse Repo",
          padding = 1,
          key = "b",
          action = function()
            require("snacks").gitbrowse()
          end,
        },
        function()
          local in_git = require("snacks").git.get_root() ~= nil
          local cmds = {
            {
              title = "All Prs",
              cmd = "gh search prs is:open author:aquilesgomez",
              key = "i",
              action = function()
                vim.fn.jobstart(
                  "gh search prs is:open author:aquilesgomez --web",
                  { detach = true }
                )
              end,
              icon = " ",
              height = 7,
            },
            {
              icon = " ",
              title = "Open PRs for this repo",
              cmd = "gh pr list -L 3",
              key = "P",
              action = function()
                vim.fn.jobstart("gh pr list --web", { detach = true })
              end,
              height = 7,
            },
            {
              icon = " ",
              title = "Review requested",
              cmd = "gh search prs is:open review-requested:AquilesGomez -L 3",
              key = "R",
              action = function()
                vim.fn.jobstart(
                  "gh search prs is:open review-requested:AquilesGomez --web",
                  { detach = true }
                )
              end,
              height = 10,
            },
          }
          return vim.tbl_map(function(cmd)
            return vim.tbl_extend("force", {
              pane = 2,
              section = "terminal",
              enabled = in_git,
              padding = 1,
              ttl = 5 * 60,
              indent = 3,
            }, cmd)
          end, cmds)
        end,
        { section = "startup" },
      },
    },
  },
  lazy = false,
}
