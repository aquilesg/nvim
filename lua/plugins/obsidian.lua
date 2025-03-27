local function create_obsidian_note(note_dir, template_name)
  local client = require("obsidian").get_client()
  local gen_id = client:new_note_id()
  local note = client:create_note {
    title = gen_id,
    id = gen_id,
    dir = note_dir,
    no_write = false,
    template = template_name,
  }
  client:open_note(note)
end

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
      "<leader>onwt",
      function()
        create_obsidian_note("Work/Tasks/", "WorkTask")
      end,
      desc = "Create new Work Task",
    },
    {
      "<leader>onwd",
      function()
        create_obsidian_note("Work/Docs/", "WorkDocument")
      end,
      desc = "Create new Work Document",
    },
    {
      "<leader>onwr",
      function()
        create_obsidian_note("Work/Research/", "WorkResearch")
      end,
      desc = "Create new Work Research Document",
    },
    {
      "<leader>onwi",
      function()
        create_obsidian_note("Work/Initiatives/", "WorkInitiative")
      end,
      desc = "Create new Work Initiative",
    },
    {
      "<leader>onwe",
      function()
        create_obsidian_note("Work/Events/", "WorkEvent")
      end,
      desc = "Create new Work Event",
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
