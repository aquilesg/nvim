local function create_obsidian_note(note_dir, template_name)
  local user_title = vim.fn.input { prompt = template_name .. " title: " }
  local client = require("obsidian").get_client()
  local gen_id = client:new_note_id()
  local note = client:create_note {
    title = user_title,
    id = user_title .. "-" .. gen_id,
    dir = note_dir,
    no_write = false,
    template = template_name,
  }
  client:open_note(note)
end

local function note_has_tags(note, tags)
  local has_tags = true
  for _, tag in ipairs(tags) do
    has_tags = has_tags and note:has_tag(tag)
    if not has_tags then
      break
    end
  end
  return has_tags
end

local function open_incomplete_notes_by_tags(incomplete_delimiter, tags)
  local client = require("obsidian").get_client()
  client:find_notes_async(incomplete_delimiter, function(notes)
    for _, note in ipairs(notes) do
      if note_has_tags(note, tags) then
        client:open_note(note)
      end
    end
  end, {
    sort = false,
    include_templates = false,
    ignore_case = true,
  })
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
    {
      "<leader>onpd",
      function()
        create_obsidian_note("Personal/Docs/", "PersonalDocument")
      end,
      desc = "Create New Personal Document",
    },
    {
      "<leader>onpr",
      function()
        create_obsidian_note("Personal/Research/", "PersonalResearchDocument")
      end,
      desc = "Create New Personal Document",
    },
    {
      "<leader>onr",
      function()
        create_obsidian_note("Personal/Recipes/", "Recipes")
      end,
      desc = "Create New Recipe Document",
    },
    -- Maintenance commands
    {
      "<leader>ocwt",
      function()
        open_incomplete_notes_by_tags("status: in-progress", { "Work/task" })
      end,
      desc = "Open current Work tasks",
    },
    {
      "<leader>ocwi",
      function()
        open_incomplete_notes_by_tags(
          "status: in-progress",
          { "Work/initiative" }
        )
      end,
      desc = "Open current Work initiatives",
    },
    {
      "<leader>ocws",
      function()
        open_incomplete_notes_by_tags(
          "status: in-progress",
          { "Work/categorize" }
        )
      end,
      desc = "Open current Work items that are stale",
    },
    {
      "<leader>ocps",
      function()
        open_incomplete_notes_by_tags(
          "status: in-progress",
          { "categorize", "personal" }
        )
      end,
      desc = "Open current Personal items that are stale",
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
              topic = function()
                return vim.fn.input {
                  prompt = "Research Topic: ",
                }
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
