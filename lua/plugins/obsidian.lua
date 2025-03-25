return {
  "obsidian-nvim/obsidian.nvim",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    {
      "<leader>ot",
      "<cmd> ObsidianToday <CR>",
      desc = "Open today's note",
    },
    {
      "<leader>oy",
      "<cmd> ObsidianYesterday <CR>",
      desc = "Open yesterday's note",
    },
    {
      "<leader>osn",
      "<cmd> ObsidianSearch <CR>",
      desc = "Obsidian search notes",
    },
    { "<leader>ost", "<cmd> ObsidianTags <CR>", desc = "Search for tags" },
    {
      "<leader>oq",
      "<cmd> ObsidianQuickSwitch <CR>",
      desc = "Quick switch to different note",
    },
    {
      "<leader>oo",
      "<cmd> ObsidianOpen <CR>",
      desc = "Open current file in Obsidian",
    },
    {
      "<leader>op",
      "<cmd> ObsidianPasteImg <CR>",
      desc = "Paste image into Obsidian note",
    },
    {
      "<leader>ont",
      "<cmd> ObsidianNewFromTemplate Work/Tasks/ <cr>",
      desc = "Create new work task",
    },
  },
  opts = {
    workspaces = {
      {
        name = "SecondBrain",
        path = "~/Repos/brain",
        overrides = {
          daily_notes = {
            folder = "DailyNotes",
            template = "daily.md",
          },
          templates = {
            subdir = "Templates",
            substitutions = {
              pretty_date = function()
                return os.date "%B %d, %Y"
              end,
            },
          },
        },
      },
    },
    ui = {
      enable = false,
    },
    mappings = {
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
    },
    use_advanced_uri = true,
    suppress_missing_scope = {
      projects_v2 = true,
    },
    follow_url_func = function(url)
      vim.fn.jobstart { "open", url }
    end,
  },
}
