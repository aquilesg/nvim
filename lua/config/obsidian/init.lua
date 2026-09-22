--- Shared settings for the brain vault: paths, document types and YAML keys.
--- The pieces obsidian.nvim does not cover (Obsidian CLI property writes, the
--- task picker, the active-notes picker, pomodoro) read their configuration
--- from here.
local M = {}

M.vault = "~/Repos/brain"
M.template_dir = "Templates"

M.properties = {
  pr_link = "pr_link",
  projects = "projects",
  contexts = "contexts",
  status = "status",
  tags = "tags",
  document_type = "document_type",
  id = "id",
  blocked_reason = "blockedBy",
}

M.directories = {
  WorkTask = "Work/Tasks/",
  WorkOncallTask = "Work/Tasks/",
  WorkDocument = "Work/Docs/",
  WorkResearch = "Work/Research/",
  WorkProject = "Work/Projects/",
  WorkEvent = "Work/Events/",
  PersonalDocument = "Personal/Docs/",
  PersonalResearchDocument = "Personal/Research/",
  Recipes = "Personal/Recipes/",
  WorkOncallShift = "Work/OnCallShifts/",
}

M.template_names = {
  WorkTask = "WorkTask",
  WorkDocument = "WorkDocument",
  WorkResearch = "WorkResearch",
  WorkEvent = "WorkEvent",
  WorkProject = "WorkProject",
  WorkOncallShift = "WorkOncallShift",
  WorkOncallTask = "WorkOncallTask",
  PersonalDocument = "PersonalDocument",
  PersonalResearchDocument = "PersonalResearchDocument",
  Recipes = "Recipes",
}

M.status = {
  active_tag = "active",
  in_progress = "In Progress",
  in_review = "In Review",
  review_complete = "Review Complete",
  abandoned = "abandoned",
  draft = "draft",
  complete = "completed",
  blocked = "blocked",
}

-- Checkbox middle characters offered by the task picker (`key` -> CLI status=).
M.task_statuses = {
  { key = " ", label = "Todo [ ]" },
  { key = "x", label = "Done [x]" },
  { key = "-", label = "Cancelled [-]" },
  { key = ">", label = "In progress [>]" },
  { key = "!", label = "Important [!]" },
  { key = "?", label = "Question [?]" },
}

--- Absolute, normalized vault directory.
---@return string
function M.vault_dir()
  return vim.fs.normalize(vim.fn.expand(M.vault))
end

--- Path of `absolute_path` relative to the vault, or the input unchanged when
--- it is not inside the vault.
---@param absolute_path string
---@return string
function M.relative_path(absolute_path)
  local abs = vim.fs.normalize(vim.fn.expand(absolute_path))
  local vault = M.vault_dir()
  if vault:sub(-1) == "/" then
    vault = vault:sub(1, -2)
  end
  if abs:sub(1, #vault) == vault then
    return abs:sub(#vault + 2)
  end
  return abs
end

--- Vault-relative path of the current buffer, or nil when it has no file.
---@return string|nil
function M.current_note_path()
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == nil or abs == "" then
    return nil
  end
  return M.relative_path(abs)
end

--- `My Title` -> `MyTitle`, the vault's filename/id convention.
---@param title string
---@return string
function M.camel_case_title(title)
  local result = title:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
  result = result:gsub('[/\\%*%?%:"<>|]', "")
  result = result
    :gsub("(%a)([%w_']*)", function(first, rest)
      return first:upper() .. rest:lower()
    end)
    :gsub("%s+", "")
  return result
end

return M
