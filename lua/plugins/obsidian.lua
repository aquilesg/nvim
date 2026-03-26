local obsidian_vault = "~/Repos/brain"
local template_dir_name = "Templates"

local note_properties = {
  pr_link = "pr_link",
  projects = "projects",
  contexts = "contexts",
  status = "status",
  tags = "tags",
  document_type = "document_type",
  id = "id",
  blocked_reason = "blockedBy",
}

local directories = {
  WorkTask = "Work/Tasks/",
  WorkOncallTask = "Work/Tasks/",
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

local note_status = {
  active_tag = "active",
  in_progress = "In Progress",
  in_review = "In Review",
  review_complete = "Review Complete",
  abandoned = "abandoned",
  draft = "draft",
  complete = "completed",
  blocked = "blocked",
}

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

local function update_note_properties(properties)
  vim.api.nvim_buf_call(vim.api.nvim_get_current_buf(), function()
    vim.api.nvim_command "write"
  end)
  local filepath = vim.api.nvim_buf_get_name(0)

  local obsidian_vault_ex = vim.fn.expand "~/Repos/brain"
  local rel_filepath = filepath
  if vim.startswith(filepath, obsidian_vault_ex) then
    rel_filepath = filepath:sub(#obsidian_vault_ex + 2) -- +2 to remove trailing slash
  end

  require("obsidian.note").UpdateNoteProperties(properties, rel_filepath)
  vim.api.nvim_command "edit!"
end

local function create_obsidian_note_with_options(opts)
  local Note = require "obsidian.note"
  local template_keys = {}
  for k, _ in pairs(template_names) do
    table.insert(template_keys, k)
  end

  local function create_for_choice(choice)
    if not choice then
      return
    end
    local user_title = vim.fn.input { prompt = choice .. " title: " }
    if not user_title or user_title == "" then
      vim.notify("Note title cannot be empty", vim.log.levels.WARN)
      return
    end
    local userID = camelCaseTitle(user_title)
    if opts and opts.insert_link then
      local text = " [[" .. userID .. "|" .. user_title .. "]]"
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local current_line = vim.api.nvim_get_current_line()
      local new_line = string.sub(current_line, 1, col)
        .. text
        .. string.sub(current_line, col + 1)
      vim.api.nvim_set_current_line(new_line)
      vim.api.nvim_win_set_cursor(0, { row, col + #text })
    end
    local _, _ = Note.createNoteFromTemplate {
      fileName = userID,
      path = directories[choice],
      templateName = template_names[choice],
      templateVariables = {
        id = userID,
        title = user_title,
      },
    }
  end

  if opts and opts.prompt_for_type then
    vim.ui.select(template_keys, {
      prompt = "Document Type",
    }, create_for_choice)
  else
    -- If type is provided directly
    create_for_choice(opts.template_type)
  end
end

local function create_obsidian_note(template_name)
  -- Find the key for the template_name
  local template_type
  for k, v in pairs(template_names) do
    if v == template_name then
      template_type = k
      break
    end
  end
  create_obsidian_note_with_options {
    template_type = template_type,
    prompt_for_type = false,
  }
end

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
    "aquilesg/obsidian",
    dependencies = { "MagicDuck/grug-far.nvim" },
    keys = {
      {
        "<leader>osv",
        function()
          require("grug-far").open {
            prefills = { paths = obsidian_vault },
          }
        end,
        desc = "Search in obsidian vault",
      },
      {
        "<leader>ost",
        function()
          require("obsidian.search").findWithinTags()
        end,
        desc = "Search for tags",
      },
      {
        "<leader>oo",
        function()
          require("obsidian.note").setActiveFile()
        end,
        desc = "Open current file in Obsidian",
      },
      {
        "<leader>ol",
        function()
          require("obsidian.search").FindLinks()
        end,
        desc = "Open links of current note",
      },
      {
        "<leader>ob",
        function()
          require("obsidian.search").FindBacklinks()
        end,
        desc = "Open backlinks of current note",
      },
      {
        "<leader>ot",
        function()
          create_obsidian_note(template_names.WorkOncallTask)
        end,
        desc = "Create new OnCall Work Task",
      },
      {
        "<leader>onws",
        function()
          create_obsidian_note(template_names.WorkOncallShift)
        end,
        desc = "Create new OnCall Work Shift",
      },
      {
        "<leader>onwt",
        function()
          create_obsidian_note(template_names.WorkTask)
        end,
        desc = "Create new Work Task",
      },
      {
        "<leader>onwd",
        function()
          create_obsidian_note(template_names.WorkDocument)
        end,
        desc = "Create new Work Document",
      },
      {
        "<leader>onwr",
        function()
          create_obsidian_note(template_names.WorkResearch)
        end,
        desc = "Create new Work Research Document",
      },
      {
        "<leader>onwi",
        function()
          create_obsidian_note(template_names.WorkInitiative)
        end,
        desc = "Create new Work Initiative",
      },
      {
        "<leader>onwe",
        function()
          create_obsidian_note(template_names.WorkEvents)
        end,
        desc = "Create new Work Event",
      },
      {
        "<leader>onpd",
        function()
          create_obsidian_note(template_names.PersonalDocument)
        end,
        desc = "Create New Personal Document",
      },
      {
        "<leader>onpr",
        function()
          create_obsidian_note(template_names.PersonalResearchDocument)
        end,
        desc = "Create New Personal ResearchDocument",
      },
      {
        "<leader>onr",
        function()
          create_obsidian_note(template_names.Recipe)
        end,
        desc = "Create New Recipe Document",
      },
      -- Maintenance commands
      {
        "<leader>ocn",
        function()
          require("obsidian.active_notes").open_picker {
            vault = obsidian_vault,
            template_dir_name = template_dir_name,
            tag = "active",
            property_keys = {
              status = note_properties.status,
              document_type = note_properties.document_type,
              id = note_properties.id,
            },
          }
        end,
        desc = "Open currently active tasks",
      },
      {
        "<leader>oct",
        function()
          require("obsidian.note").UpdateNoteTask()
        end,
        desc = "Open current note tasks",
      },
      -- Status change
      {
        "<leader>omc",
        function()
          local rel = require("obsidian.util").get_relative_path(
            vim.api.nvim_buf_get_name(0),
            obsidian_vault
          )
          local props = require("obsidian.note_properties").properties_for_mark_complete(
            rel,
            {
              tags_key = note_properties.tags,
              status_key = note_properties.status,
              status_complete = note_status.complete,
              exclude_tag = note_status.active_tag,
            }
          )
          update_note_properties(props)
        end,
        desc = "Mark complete",
      },
      {
        "<leader>omi",
        function()
          local rel = require("obsidian.util").get_relative_path(
            vim.api.nvim_buf_get_name(0),
            obsidian_vault
          )
          local props =
            require("obsidian.note_properties").properties_for_mark_in_progress(
              rel,
              {
                tags_key = note_properties.tags,
                status_key = note_properties.status,
                status_in_progress = note_status.in_progress,
                active_tag = note_status.active_tag,
              }
            )
          update_note_properties(props)
        end,
        desc = "Mark document in progress",
      },
      {
        "<leader>oma",
        function()
          vim.ui.input({
            prompt = "Why was this abandoned?",
          }, function(response)
            local props = {
              {
                name = note_properties.status,
                value = note_status.abandoned,
                type = "text",
              },
              {
                name = "abandon_reason",
                value = response,
                type = "text",
              },
            }
            update_note_properties(props)
          end)
        end,
        desc = "Mark document abandoned",
      },
      {
        "<leader>omb",
        function()
          vim.ui.input({
            prompt = "Why is this blocked? (Link ticket if available)",
          }, function(response)
            local rel = require("obsidian.util").get_relative_path(
              vim.api.nvim_buf_get_name(0),
              obsidian_vault
            )
            local props = require("obsidian.note_properties").properties_for_mark_blocked(
              rel,
              response,
              {
                blocked_property = note_properties.blocked_reason,
                status_property = note_properties.status,
                status_value = note_status.blocked,
              }
            )
            if props then
              update_note_properties(props)
            end
          end)
        end,
        desc = "Mark document blocked",
      },
      {
        "<leader>omr",
        function()
          vim.ui.input({
            prompt = "What is the PR Link (if available)",
          }, function(response)
            if not response or response == "" then
              local props = {
                {
                  name = note_properties.status,
                  value = note_status.in_review,
                  type = "text",
                },
              }
              update_note_properties(props)
              return
            end

            local rel = require("obsidian.util").get_relative_path(
              vim.api.nvim_buf_get_name(0),
              obsidian_vault
            )
            local pr_links = vim.list_extend(
              {},
              require("obsidian.note_properties").get_string_list_property(
                rel,
                note_properties.pr_link
              )
            )
            table.insert(pr_links, response)

            local props = {
              {
                name = note_properties.status,
                value = note_status.in_review,
                type = "text",
              },
              {
                name = note_properties.pr_link,
                value = pr_links,
                type = "list",
              },
            }
            update_note_properties(props)
          end)
        end,
        desc = "Mark document as in-review",
      },
      {
        "<leader>omR",
        function()
          local props = {
            {
              name = note_properties.status,
              value = note_status.review_complete,
              type = "text",
            },
          }
          update_note_properties(props)
        end,
        desc = "Mark review complete",
      },
      {
        "<leader>oid",
        function()
          create_obsidian_note_with_options {
            insert_link = true,
            prompt_for_type = true,
          }
        end,
        mode = { "n" },
        desc = "Insert Link to Document",
      },
    },
    opts = {
      obsidian_vault_dir = obsidian_vault,
      template_dir = template_dir_name,
      obsidian_cli = "/opt/homebrew/bin/obsidian",
      -- Normal mode [[wiki]] follow (see `obsidian.wiki_follow` in the plugin)
      wiki_follow = true,
    },
  },
}
