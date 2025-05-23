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
  template = "template",
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

local function search_all_notes_for_tag(tags)
  local client = require("obsidian").get_client()
  client:find_notes_async(tags, function(notes)
    for _, note in ipairs(notes) do
      client:open_note(note)
    end
  end, {
    sort = false,
    include_templates = false,
    ignore_case = true,
  })
end

local function open_notes_by_document_frontmatter(document_type, status)
  local client = require("obsidian").get_client()
  local search_term = "document_type: " .. document_type
  client:find_notes_async(search_term, function(notes)
    for _, note in ipairs(notes) do
      local current_status = note:get_field "status"
      if current_status == status then
        client:open_note(note)
      end
    end
  end, {
    sort = false,
    include_templates = false,
    ignore_case = true,
  })
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

local function create_status_front_matter(status)
  return "status: " .. status
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
        open_incomplete_notes_by_tags(
          create_status_front_matter(note_status.in_progress),
          { "Work/task" }
        )
        open_incomplete_notes_by_tags(
          create_status_front_matter(note_status.in_review),
          { "Work/task" }
        )
        open_incomplete_notes_by_tags(
          create_status_front_matter(note_status.blocked),
          { "Work/task" }
        )
      end,
      desc = "Open current Work tasks",
    },
    {
      "<leader>ocwi",
      function()
        open_notes_by_document_frontmatter(
          "initiative",
          note_status.in_progress
        )
        open_notes_by_document_frontmatter("initiative", note_status.in_review)
      end,
      desc = "Open current Work initiatives",
    },
    {
      "<leader>ocws",
      function()
        search_all_notes_for_tag { "Work/categorize" }
      end,
      desc = "Open current Work items that are stale",
    },
    {
      "<leader>ocwr",
      function()
        open_notes_by_document_frontmatter("research", note_status.in_progress)
        open_notes_by_document_frontmatter("research", note_status.in_review)
      end,
      desc = "Open current Work Research",
    },
    {
      "<leader>ocps",
      function()
        search_all_notes_for_tag { "Personal/categorize" }
      end,
      desc = "Open current Personal items that are stale",
    },
    {
      "<leader>ocpt",
      function()
        open_incomplete_notes_by_tags(note_status.in_progress, { "Personal" })
      end,
      desc = "Open current Personal items that are in progress",
    },
    -- Status change
    {
      "<leader>omc",
      function()
        update_current_note_field("status", note_status.complete)
        update_current_note_field("completion_date", os.date "%Y-%m-%d")
      end,
      desc = "Mark complete",
    },
    {
      "<leader>omi",
      function()
        update_current_note_field("status", note_status.in_progress)
      end,
      desc = "Mark document in progress",
    },
    {
      "<leader>oma",
      function()
        vim.ui.input({
          prompt = "Why was this abandoned?",
        }, function(response)
          update_current_note_field("status", note_status.abandoned)
          update_current_note_field("abandon_date", os.date "%Y-%m-%d")
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
          update_current_note_field(note_status.blocked, note_status.blocked)
          update_current_note_field("blocked_date", os.date "%Y-%m-%d")
        end)
      end,
    },
    {
      "<leader>omr",
      function()
        update_current_note_field("status", note_status.in_review)
        update_current_note_field("review_start", os.date "%Y-%m-%d")
      end,
      desc = "Mark document as in-review",
    },
    {
      "<leader>omR",
      function()
        update_current_note_field("status", note_status.review_complete)
        update_current_note_field("review_complete", os.date "%Y-%m-%d")
        update_current_note_field("reviewed", "yes")
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
    use_advanced_uri = true,
    suppress_missing_scope = {
      projects_v2 = true,
    },
    follow_url_func = function(url)
      vim.fn.jobstart { "open", url }
    end,
  },
}
