local directories = {
  WorkTask = "Work/Tasks/",
  WorkDocument = "Work/Docs/",
  WorkResearch = "Work/Research/",
  WorkInitiative = "Work/Initiatives/",
  WorkEvents = "Work/Events/",
  PersonalDocument = "Personal/Docs/",
  PersonalResearchDocument = "Personal/Research/",
  Recipe = "Personal/Recipes/",
}

local template_names = {
  WorkTask = "WorkTask",
  WorkDocument = "WorkDocument",
  WorkResearch = "WorkResearch",
  WorkInitiative = "WorkInitiative",
  WorkEvents = "WorkEvent",
  PersonalDocument = "PersonalDocument",
  PersonalResearchDocument = "PersonalResearchDocument",
  Recipe = "Recipes",
}

local document_types = {
  initiative = "initiative",
  task = "task",
  research = "research",
  event = "event",
  investigation = "investigation",
  guide = "guide",
  reference = "reference",
  note = "note",
  plan = "plan",
}

local note_status = {
  all_notes = "",
  in_progress = "in-progress",
  in_review = "in-review",
  review_complete = "review-complete",
  abandoned = "abandoned",
  complete = "complete",
  blocked = "blocked",
}

local function get_notes_by_tags(tags)
  local client = require("obsidian").get_client()
  local found_notes = {}

  for _, tag in ipairs(tags) do
    local found_notes_tags = client:find_notes(tag, {
      sort = false,
      include_templates = false,
      ignore_case = true,
    })

    found_notes = vim.list_extend(found_notes, found_notes_tags)
  end
  return found_notes
end

local function display_note_picker(note_table, prompt, opts)
  opts = opts or {}
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  pickers
    .new(opts, {
      prompt_title = prompt,
      finder = finders.new_table {
        results = note_table,
        entry_maker = function(note)
          return {
            value = note,
            display = note:display_name(),
            ordinal = note:display_name(),
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local client = require("obsidian").get_client()
          actions.close(prompt_bufnr)
          local selected_note = action_state.get_selected_entry().value
          client:open_note(selected_note)
        end)
        return true
      end,
    })
    :find()
end

local function create_obsidian_note(note_dir, template_name, should_not_open)
  local user_title = vim.fn.input { prompt = template_name .. " title: " }
  local client = require("obsidian").get_client()
  local gen_id
  if note_dir == directories.Recipe then
    gen_id = user_title .. "-" .. client:new_note_id(user_title)
  else
    gen_id = client:new_note_id(user_title)
  end
  local note = client:create_note {
    title = user_title,
    id = gen_id,
    dir = note_dir,
    no_write = false,
    template = template_name,
  }
  if should_not_open then
    return gen_id, user_title
  end
  client:open_note(note)
end

local function get_incomplete_notes_by_document_type(document_type)
  local incomplete_delimiter =
    { note_status.in_progress, note_status.in_review, note_status.blocked }
  local client = require("obsidian").get_client()
  local found_notes = {}
  local search_term = "document_type: " .. document_type
  local all_notes = client:find_notes(search_term, {
    sort = false,
    include_templates = false,
    ignore_case = true,
  })

  for _, delimiter in ipairs(incomplete_delimiter) do
    for _, note in ipairs(all_notes) do
      if note:get_field "status" == delimiter then
        table.insert(found_notes, note)
      end
    end
  end
  return found_notes
end

local function update_current_note_field(field, value, note)
  local client = require("obsidian").get_client()
  if note == nil then
    note = client:current_note(vim.api.nvim_get_current_buf(), {
      load_contents = false,
      collect_anchor_links = false,
      collect_blocks = false,
    })
  end

  if note ~= nil then
    local front_matter = note:frontmatter()
    front_matter[field] = value
    note:save_to_buffer {
      frontmatter = front_matter,
      insert_frontmatter = true,
    }
  end
end

local function get_incomplete_notes_by_tags(tags)
  local incomplete_delimiter =
    { note_status.in_progress, note_status.in_review, note_status.blocked }
  local found_notes = {}

  local tagged_notes = get_notes_by_tags(tags)
  for _, note in ipairs(tagged_notes) do
    local current_status = note:get_field "status"
    if vim.tbl_contains(incomplete_delimiter, current_status) then
      table.insert(found_notes, note)
    end
  end
  return found_notes
end

local function modify_note_status(status, note)
  local client = require("obsidian").get_client()
  if note == nil then
    note = client:current_note(vim.api.nvim_get_current_buf(), {
      load_contents = false,
      collect_anchor_links = false,
      collect_blocks = false,
    })
  end
  if note ~= nil then
    local front_matter = note:frontmatter()
    front_matter["status"] = status
    front_matter[status .. "-modification-date"] = os.date "%Y-%m-%d"
    note:save_to_buffer {
      frontmatter = front_matter,
      insert_frontmatter = true,
    }
  end
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
      "<leader>oip",
      "<cmd> ObsidianPasteImg <CR>",
      desc = "Paste image into Obsidian note",
    },
    {
      "<leader>onwt",
      function()
        create_obsidian_note(directories.WorkTask, template_names.WorkTask)
      end,
      desc = "Create new Work Task",
    },
    {
      "<leader>onwd",
      function()
        create_obsidian_note(
          directories.WorkDocument,
          template_names.WorkDocument
        )
      end,
      desc = "Create new Work Document",
    },
    {
      "<leader>onwr",
      function()
        create_obsidian_note(
          directories.WorkResearch,
          template_names.WorkResearch
        )
      end,
      desc = "Create new Work Research Document",
    },
    {
      "<leader>onwi",
      function()
        create_obsidian_note(
          directories.WorkInitiative,
          template_names.WorkInitiative
        )
      end,
      desc = "Create new Work Initiative",
    },
    {
      "<leader>onwe",
      function()
        create_obsidian_note(directories.WorkEvents, template_names.WorkEvents)
      end,
      desc = "Create new Work Event",
    },
    {
      "<leader>onpd",
      function()
        create_obsidian_note(
          directories.PersonalDocument,
          template_names.PersonalDocument
        )
      end,
      desc = "Create New Personal Document",
    },
    {
      "<leader>onpr",
      function()
        create_obsidian_note(
          directories.PersonalResearchDocument,
          template_names.PersonalResearchDocument
        )
      end,
      desc = "Create New Personal ResearchDocument",
    },
    {
      "<leader>onr",
      function()
        create_obsidian_note(directories.Recipe, template_names.Recipe)
      end,
      desc = "Create New Recipe Document",
    },
    -- Maintenance commands
    {
      "<leader>ocwt",
      function()
        local notes = get_incomplete_notes_by_tags { "Work/task" }
        display_note_picker(notes, "Chose the Work Task to open")
      end,
      desc = "Open current Work tasks",
    },
    {
      "<leader>ocwi",
      function()
        local initiatives =
          get_incomplete_notes_by_document_type(document_types.initiative)
        display_note_picker(initiatives, "Pick initiative to open")
      end,
      desc = "Open current Work initiatives",
    },
    {
      "<leader>ocws",
      function()
        local stale_notes = get_notes_by_tags { "Work/categorize" }
        display_note_picker(stale_notes, "Pick stale note")
      end,
      desc = "Open current Work items that are stale",
    },
    {
      "<leader>ocwr",
      function()
        local research_documents =
          get_incomplete_notes_by_document_type(document_types.research)
        display_note_picker(
          research_documents,
          "Pick research document to open"
        )
      end,
      desc = "Open current Work Research",
    },
    {
      "<leader>ocps",
      function()
        local stale_notes = get_notes_by_tags { "Personal/categorize" }
        display_note_picker(stale_notes, "Pick stale note")
      end,
      desc = "Open current Personal items that are stale",
    },
    {
      "<leader>ocpt",
      function()
        local notes = get_incomplete_notes_by_tags { "Personal" }
        display_note_picker(notes, "Chose document to open")
      end,
      desc = "Open current Personal items that are in progress",
    },
    -- Status change
    {
      "<leader>omc",
      function()
        modify_note_status(note_status.complete)
      end,
      desc = "Mark complete",
    },
    {
      "<leader>omi",
      function()
        modify_note_status(note_status.in_progress)
      end,
      desc = "Mark document in progress",
    },
    {
      "<leader>oma",
      function()
        vim.ui.input({
          prompt = "Why was this abandoned?",
        }, function(response)
          modify_note_status(note_status.abandoned)
          update_current_note_field("abandon_reason", response)
        end)
      end,
      desc = "Mark document abandoned",
    },
    {
      -- TODO: it'd be nice if this automatically backlinked
      "<leader>omb",
      function()
        vim.ui.input({
          prompt = "Why is this blocked? (Link ticket if available)",
        }, function(response)
          modify_note_status(note_status.blocked)
          update_current_note_field("blocked-reason", response)
        end)
      end,
    },
    {
      "<leader>omr",
      function()
        modify_note_status(note_status.in_review)
      end,
      desc = "Mark document as in-review",
    },
    {
      "<leader>omR",
      function()
        modify_note_status(note_status.review_complete)
      end,
      desc = "Mark review complete",
    },
    {
      "<F2>",
      function()
        local template_keys = {}
        for k, _ in pairs(template_names) do
          table.insert(template_keys, k)
        end
        vim.ui.select(template_keys, {
          prompt = "Document Type",
        }, function(choice)
          local id, title = create_obsidian_note(
            directories[choice],
            template_names[choice],
            true
          )
          local text = "[[" .. id .. "|" .. title .. "]]"
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local current_line = vim.api.nvim_get_current_line()
          local new_line = string.sub(current_line, 1, col)
            .. text
            .. string.sub(current_line, col + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, { row, col + #text })
        end)
      end,
      mode = { "n", "i" },
      desc = "Insert Link to Document",
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
    callbacks = {
      ---@param client obsidian.Client
      ---@param note obsidian.Note
      enter_note = function(client, note)
        local aliases = note.aliases
        if aliases and #aliases > 0 then
          local shortest = aliases[1]
          for _, alias in ipairs(aliases) do
            if #alias < #shortest then
              shortest = alias
            end
          end
          vim.b.obsidian_alias = note.bufnr .. "  " .. shortest
        end
      end,
    },
    mappings = {
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
    },
    open_notes_in = "vsplit",
    open = {
      use_advanced_uri = true,
    },
    suppress_missing_scope = {
      projects_v2 = true,
    },
    follow_url_func = function(url)
      vim.fn.jobstart { "open", url }
    end,
  },
}
