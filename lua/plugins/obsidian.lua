local vault = require "config.obsidian"

local props = vault.properties
local status = vault.status

local function notes()
  return require "config.obsidian.notes"
end

local function properties()
  return require "config.obsidian.properties"
end

--- Keymap that creates a note of one template type.
---@param lhs string
---@param type_key string
---@param desc string
local function new_note_key(lhs, type_key, desc)
  return {
    lhs,
    function()
      notes().create_for_type(type_key)
    end,
    desc = desc,
  }
end

local keys = {
  {
    "<leader>osv",
    function()
      require("grug-far").open { prefills = { paths = vault.vault } }
    end,
    desc = "Search in obsidian vault",
  },
  { "<leader>ost", "<cmd> Obsidian tags <CR>", desc = "Search for tags" },
  {
    "<leader>osf",
    "<cmd> Obsidian quick_switch <CR>",
    desc = "Find Obsidian note by name",
  },
  {
    "<leader>oo",
    "<cmd> Obsidian open <CR>",
    desc = "Open current file in Obsidian",
  },
  {
    "<leader>ol",
    "<cmd> Obsidian links <CR>",
    desc = "Open links of current note",
  },
  {
    "<leader>ob",
    "<cmd> Obsidian backlinks <CR>",
    desc = "Open backlinks of current note",
  },
  new_note_key("<leader>ot", "WorkOncallTask", "Create new OnCall Work Task"),
  new_note_key("<leader>onws", "WorkOncallShift", "Create new OnCall Work Shift"),
  new_note_key("<leader>onwt", "WorkTask", "Create new Work Task"),
  new_note_key("<leader>onwd", "WorkDocument", "Create new Work Document"),
  new_note_key("<leader>onwr", "WorkResearch", "Create new Work Research Document"),
  new_note_key("<leader>onwp", "WorkProject", "Create new Work Project"),
  new_note_key("<leader>onwe", "WorkEvent", "Create new Work Event"),
  new_note_key("<leader>onpd", "PersonalDocument", "Create New Personal Document"),
  new_note_key(
    "<leader>onpr",
    "PersonalResearchDocument",
    "Create New Personal ResearchDocument"
  ),
  new_note_key("<leader>onr", "Recipes", "Create New Recipe Document"),
  -- Maintenance commands
  {
    "<leader>ocn",
    function()
      require("config.obsidian.active_notes").open_picker {
        tag = status.active_tag,
        property_keys = {
          status = props.status,
          document_type = props.document_type,
          id = props.id,
        },
      }
    end,
    desc = "Open currently active tasks",
  },
  {
    "<leader>oct",
    function()
      require("config.obsidian.tasks").pick()
    end,
    desc = "Open current note tasks",
  },
  -- Status change
  {
    "<leader>omc",
    function()
      local p = properties()
      p.update(p.for_mark_complete(vault.current_note_path(), {
        tags_key = props.tags,
        status_key = props.status,
        status_complete = status.complete,
        exclude_tag = status.active_tag,
      }))
    end,
    desc = "Mark complete",
  },
  {
    "<leader>omi",
    function()
      local p = properties()
      p.update(p.for_mark_in_progress(vault.current_note_path(), {
        tags_key = props.tags,
        status_key = props.status,
        status_in_progress = status.in_progress,
        active_tag = status.active_tag,
      }))
    end,
    desc = "Mark document in progress",
  },
  {
    "<leader>oma",
    function()
      local p = properties()
      p.update(p.for_mark_complete(vault.current_note_path(), {
        tags_key = props.tags,
        status_key = props.status,
        status_complete = status.abandoned,
        exclude_tag = status.active_tag,
      }))
    end,
    desc = "Mark document abandoned",
  },
  {
    "<leader>omb",
    function()
      vim.ui.input({
        prompt = "Why is this blocked? (Link ticket if available)",
      }, function(response)
        local p = properties()
        p.update(p.for_mark_blocked(vault.current_note_path(), response, {
          blocked_property = props.blocked_reason,
          status_property = props.status,
          status_value = status.blocked,
        }))
      end)
    end,
    desc = "Mark document blocked",
  },
  {
    "<leader>omr",
    function()
      vim.ui.input(
        { prompt = "What is the PR Link (if available)" },
        function(response)
          local p = properties()
          local rows = {
            { name = props.status, value = status.in_review, type = "text" },
          }
          if response and response ~= "" then
            local rel = vault.current_note_path()
            local pr_links =
              vim.list_extend({}, p.get_string_list(rel, props.pr_link))
            table.insert(pr_links, response)
            rows[#rows + 1] =
              { name = props.pr_link, value = pr_links, type = "list" }
          end
          p.update(rows)
        end
      )
    end,
    desc = "Mark document as in-review",
  },
  {
    "<leader>omR",
    function()
      properties().update {
        { name = props.status, value = status.review_complete, type = "text" },
      }
    end,
    desc = "Mark review complete",
  },
  {
    "<leader>oid",
    function()
      notes().create { insert_link = true, prompt_for_type = true }
    end,
    mode = { "n" },
    desc = "Insert Link to Document",
  },
}

return {
  {
    "MagicDuck/grug-far.nvim",
    keys = {
      {
        "<leader>fr",
        "<cmd> GrugFar <CR>",
        desc = "Find and Replace",
      },
    },
    opts = {},
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    dependencies = {
      "MagicDuck/grug-far.nvim",
      "nvim-telescope/telescope.nvim",
    },
    event = {
      "BufReadPre " .. vim.fn.expand(vault.vault) .. "/**.md",
      "BufNewFile " .. vim.fn.expand(vault.vault) .. "/**.md",
    },
    keys = keys,
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false,
      workspaces = {
        { name = "brain", path = vault.vault },
      },
      templates = {
        folder = vault.template_dir,
        date_format = "YYYY-MM-DD",
      },
      -- Frontmatter in this vault is hand-rolled (document_type, status,
      -- contexts, ...); let the templates and the Obsidian CLI own it rather
      -- than having obsidian.nvim rewrite id/aliases/tags on every write.
      frontmatter = { enabled = false },
      -- markdown.nvim already renders notes, and lualine owns the statusline.
      ui = { enable = false },
      footer = { enabled = false },
      statusline = { enabled = false },
      picker = { name = "telescope.nvim" },
      note_id_func = vault.camel_case_title,
      completion = { create_new = false },
    },
  },
}
