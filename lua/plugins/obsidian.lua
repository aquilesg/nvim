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

local update_note_properties =
  require("obsidian.note_properties").update_note_properties

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
          require("obsidian.note_creation").create_for_type "WorkOncallTask"
        end,
        desc = "Create new OnCall Work Task",
      },
      {
        "<leader>onws",
        function()
          require("obsidian.note_creation").create_for_type "WorkOncallShift"
        end,
        desc = "Create new OnCall Work Shift",
      },
      {
        "<leader>onwt",
        function()
          require("obsidian.note_creation").create_for_type "WorkTask"
        end,
        desc = "Create new Work Task",
      },
      {
        "<leader>onwd",
        function()
          require("obsidian.note_creation").create_for_type "WorkDocument"
        end,
        desc = "Create new Work Document",
      },
      {
        "<leader>onwr",
        function()
          require("obsidian.note_creation").create_for_type "WorkResearch"
        end,
        desc = "Create new Work Research Document",
      },
      {
        "<leader>onwi",
        function()
          require("obsidian.note_creation").create_for_type "WorkInitiative"
        end,
        desc = "Create new Work Initiative",
      },
      {
        "<leader>onwe",
        function()
          require("obsidian.note_creation").create_for_type "WorkEvents"
        end,
        desc = "Create new Work Event",
      },
      {
        "<leader>onpd",
        function()
          require("obsidian.note_creation").create_for_type "PersonalDocument"
        end,
        desc = "Create New Personal Document",
      },
      {
        "<leader>onpr",
        function()
          require("obsidian.note_creation").create_for_type "PersonalResearchDocument"
        end,
        desc = "Create New Personal ResearchDocument",
      },
      {
        "<leader>onr",
        function()
          require("obsidian.note_creation").create_for_type "Recipe"
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
          local props =
            require("obsidian.note_properties").properties_for_mark_complete(
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
            local props =
              require("obsidian.note_properties").properties_for_mark_blocked(
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
          require("obsidian.note_creation").create_with_options {
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
      directories = directories,
      template_names = template_names,
      note_properties = note_properties,
    },
  },
}
