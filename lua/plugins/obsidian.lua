local directories = {
  WorkTask = "Work/Tasks/",
  WorkDocument = "Work/Docs/",
  WorkResearch = "Work/Research/",
  WorkInitiative = "Work/Initiatives/",
  WorkEvents = "Work/Events/",
  PersonalDocument = "Personal/Docs/",
  PersonalResearchDocument = "Personal/Research/",
  Recipe = "Personal/Recipes/",
  WorkOncallShift = "Work/OnCallShifts/",
}

local template_names = {
  WorkTask = "WorkTask",
  WorkDocument = "WorkDocument",
  WorkResearch = "WorkResearch",
  WorkInitiative = "WorkInitiative",
  WorkEvents = "WorkEvent",
  WorkProjectScoping = "WorkProjectScoping",
  WorkOncallShift = "WorkOncallShift",
  WorkOncallTask = "WorkOncallTask",
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
  project_scoping = "project_scoping",
  on_call_shift = "on-call-shift",
  on_call_task = "on-call-task",
}

local note_status = {
  all_notes = "",
  in_progress = "In Progress",
  in_review = "In Review",
  review_complete = "Review Complete",
  abandoned = "abandoned",
  draft = "draft",
  complete = "completed",
  blocked = "blocked",
}

local front_matter_fields = {
  pr_link = "pr_link",
  projects = "projects",
  status = "status",
}

local function get_notes_by_tags(tags)
  local search_client = require "obsidian.search"
  local found_notes = {}

  for _, tag in ipairs(tags) do
    local found_notes_tags = search_client.find_notes(tag, {
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
          local doc_type = note:get_field "document_type"
          if type(doc_type) == "table" then
            doc_type = vim.inspect(doc_type)
          end
          doc_type = doc_type or ""
          local display = note:display_name()
          if doc_type ~= "" then
            display = display .. " (" .. doc_type .. ")"
          end
          return {
            value = note,
            display = display,
            ordinal = display,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selected_note = action_state.get_selected_entry().value
          selected_note:open {}
        end)
        return true
      end,
    })
    :find()
end

local function camelCaseTitle(title)
  local result = title:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
  result = result:gsub('[/\\%*%?%:"<>|]', "")
  result = result
    :gsub("(%a)([%w_']*)", function(first, rest)
      return first:upper() .. rest:lower()
    end)
    :gsub("%s+", "")
  return result
end

local function update_note_frontmatter(field, value, note)
  local Note = require "obsidian.note"
  if note == nil then
    note = Note.from_buffer(vim.api.nvim_get_current_buf(), {
      load_contents = false,
      collect_anchor_links = false,
      collect_blocks = false,
    })
  end

  if note ~= nil then
    note:add_field(field, value)
    note:save_to_buffer { insert_frontmatter = true }
  end
end

local function get_incomplete_notes_by_tags(tags)
  local incomplete_delimiter =
    { note_status.in_progress, note_status.in_review, note_status.blocked }
  local found_notes = {}
  local seen_ids = {}

  local tagged_notes = get_notes_by_tags(tags)
  for _, note in ipairs(tagged_notes) do
    local current_status = note:get_field "status"
    local note_id = note.id
    if
      vim.tbl_contains(incomplete_delimiter, current_status)
      and not seen_ids[note_id]
    then
      table.insert(found_notes, note)
      seen_ids[note_id] = true
    end
  end
  return found_notes
end

local function create_obsidian_note(note_dir, template_name)
  local Note = require "obsidian.Note"
  local title
  if template_name == template_names.WorkOncallShift then
    title = vim.fn.input { prompt = template_name .. " Oncall rotation name: " }
  else
    title = vim.fn.input { prompt = template_name .. " title: " }
  end
  if not title or title == "" then
    vim.notify("Note title cannot be empty", vim.log.levels.WARN)
    return
  end

  local camel_case_title = camelCaseTitle(title)
  local new_note_id

  if template_name == template_names.WorkEvents then
    new_note_id = os.date "%Y-%m-%d-" .. camel_case_title
  elseif template_name == template_names.WorkOncallShift then
    new_note_id =
      camelCaseTitle("on-call-" .. camel_case_title .. os.date "%Y-%m-%d-")
  else
    new_note_id = camel_case_title
  end

  local note = Note.create {
    title = title,
    id = new_note_id,
    dir = note_dir,
    should_write = true,
    template = template_name,
  }

  note:open()
end

return {
  "obsidian-nvim/obsidian.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    {
      "<leader>osn",
      "<cmd> Obsidian search <CR>",
      desc = "Obsidian search notes",
    },
    { "<leader>ost", "<cmd> Obsidian tags <CR>", desc = "Search for tags" },
    {
      "<leader>oo",
      "<cmd> Obsidian open <CR>",
      desc = "Open current file in Obsidian",
    },
    {
      "<leader>oip",
      "<cmd> Obsidian paste_img <CR>",
      desc = "Paste image into Obsidian note",
    },
    {
      "<leader>obl",
      "<cmd> Obsidian backlinks <CR>",
      desc = "Open backlinks of current note",
    },
    {
      "<leader>ot",
      function()
        create_obsidian_note(
          directories.WorkTask,
          template_names.WorkOncallTask
        )
      end,
      desc = "Create new OnCall Work Task",
    },
    {
      "<leader>onws",
      function()
        create_obsidian_note(
          directories.WorkOncallShift,
          template_names.WorkOncallShift
        )
      end,
      desc = "Create new OnCall Work Shift",
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
        local notes = get_incomplete_notes_by_tags {
          "Work/IH/task",
          "Work/IH/project",
          "Work/IH/initiative",
          "Work/platform-research",
          "Work/categorize",
        }
        display_note_picker(notes, "Chose the Work Task to open")
      end,
      desc = "Open current Work tasks",
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
        update_note_frontmatter("completedDate", os.date "%Y-%m-%d")
        update_note_frontmatter(
          front_matter_fields.status,
          note_status.complete
        )
      end,
      desc = "Mark complete",
    },
    {
      "<leader>omi",
      function()
        update_note_frontmatter(
          front_matter_fields.status,
          note_status.in_progress
        )
      end,
      desc = "Mark document in progress",
    },
    {
      "<leader>oma",
      function()
        vim.ui.input({
          prompt = "Why was this abandoned?",
        }, function(response)
          update_note_frontmatter(
            front_matter_fields.status,
            note_status.abandoned
          )
          update_note_frontmatter("abandon_reason", response)
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
          update_note_frontmatter(
            front_matter_fields.status,
            note_status.blocked
          )
          update_note_frontmatter("blocked-reason", response)
        end)
      end,
    },
    {
      "<leader>omr",
      function()
        update_note_frontmatter(
          front_matter_fields.status,
          note_status.in_review
        )
        vim.ui.input({
          prompt = "What is the PR Link (if available)",
        }, function(response)
          update_note_frontmatter(front_matter_fields.pr_link, response)
        end)
      end,
      desc = "Mark document as in-review",
    },
    {
      "<leader>omR",
      function()
        update_note_frontmatter(
          front_matter_fields.status,
          note_status.review_complete
        )
      end,
      desc = "Mark review complete",
    },
    {
      "<leader>oid",
      function()
        local template_keys = {}
        for k, _ in pairs(template_names) do
          table.insert(template_keys, k)
        end
        vim.ui.select(template_keys, {
          prompt = "Document Type",
        }, function(choice)
          if not choice then
            return
          end

          local Note = require "obsidian.note"
          local user_title = vim.fn.input { prompt = choice .. " title: " }
          if not user_title then
            return
          end
          local userID = camelCaseTitle(user_title)
          ---@type obsidian.Note
          local new_note = Note.create {
            title = user_title,
            id = userID,
            dir = directories[choice],
            template = template_names[choice],
            should_write = true,
          }

          local text = " [[" .. userID .. "|" .. user_title .. "]]"
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local current_line = vim.api.nvim_get_current_line()
          local new_line = string.sub(current_line, 1, col)
            .. text
            .. string.sub(current_line, col + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, { row, col + #text })

          new_note:open {}
        end)
      end,
      mode = { "n" },
      desc = "Insert Link to Document",
    },
  },
  opts = {
    legacy_commands = false,
    completion = {
      nvim_cmp = true,
      blink = false,
      min_chars = 2,
    },
    statusline = {
      enabled = false,
    },
    footer = {
      enabled = true,
    },
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
              week = function()
                local now = os.time()
                local future = now + (7 * 24 * 60 * 60)
                local current_str = os.date("%Y-%m-%d", now)
                local future_str = os.date("%Y-%m-%d", future)
                return current_str .. " - " .. future_str
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
      ---@param note obsidian.Note
      enter_note = function(note)
        -- Name the buffer so I can find it easily
        local aliases = note.aliases
        if aliases and #aliases > 0 then
          local shortest = aliases[1]
          for _, alias in ipairs(aliases) do
            if #alias < #shortest then
              shortest = alias
            end
          end
          local bufnr = note.bufnr or vim.api.nvim_get_current_buf()
          vim.b.obsidian_alias = bufnr .. " 󱓟 " .. shortest
        end
      end,
    },
    open_notes_in = "vsplit",
    suppress_missing_scope = {
      projects_v2 = true,
    },
    follow_url_func = function(url)
      vim.fn.jobstart { "open", url }
    end,
    disable_frontmatter = true,
  },
}
