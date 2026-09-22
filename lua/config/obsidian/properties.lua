--- Read and write note YAML properties through the Obsidian CLI, plus the
--- status transitions behind the `<leader>om*` keymaps.
local M = {}

local cli = require "config.obsidian.cli"
local vault = require "config.obsidian"

--- Serialize values for `obsidian property:set`: comma-separated string lists
--- vs a JSON array of objects.
---@param value any
---@return string
function M.encode_value(value)
  if type(value) ~= "table" then
    return tostring(value)
  end
  if #value == 0 then
    return ""
  end
  if type(value[1]) == "table" then
    return vim.fn.json_encode(value)
  end
  return table.concat(value, ",")
end

--- Write property rows to a note.
---@param properties table[] # { name, value, type } rows
---@param note_rel string # path relative to the vault
function M.set(properties, note_rel)
  for _, property in ipairs(properties or {}) do
    local raw = M.encode_value(property.value)
    local out = cli.run_text(
      "property:set name="
        .. vim.fn.shellescape(property.name)
        .. " value="
        .. vim.fn.shellescape(raw)
        .. " type="
        .. vim.fn.shellescape(property.type)
        .. " path="
        .. vim.fn.shellescape(note_rel)
    )
    if out == nil then
      cli.log("Failed to set property: " .. property.name .. "\n")
    end
  end
end

--- Read selected properties of a note.
---@param note_rel string|nil # defaults to the current buffer
---@param keys string[]
---@return table<string, any>
function M.get(note_rel, keys)
  local target = note_rel or vault.current_note_path()
  if not target then
    return {}
  end

  local result = cli.run_json(
    string.format('properties format=json path="%s"', cli.escape(target))
  )
  if not result then
    return {}
  end

  local out = {}
  for _, key in ipairs(keys) do
    if result[key] ~= nil then
      out[key] = result[key]
    end
  end
  return out
end

--- Read a list property as a list of strings (tags, `pr_link`, ...).
---@param note_rel string
---@param key string
---@return string[]
function M.get_string_list(note_rel, key)
  local existing = M.get(note_rel, { key })
  local list = existing[key] or {}
  if type(list) == "string" then
    list = { list }
  end
  return list
end

--- If `response` resolves to a single `.md` note under the vault, return
--- `[[path/no-ext]]`; otherwise the trimmed string.
---@param response string
---@return string
function M.wiki_link_if_vault_note(response)
  local r = vim.trim(response or "")
  if r == "" or r:match "^%[%[.+%]%]$" then
    return r
  end
  local root = vault.vault_dir()
  local target = r:gsub("\\", "/")
  if target:lower():sub(-3) == ".md" then
    target = target:sub(1, -4)
  end
  local candidate = vim.fs.normalize(vim.fs.joinpath(root, target .. ".md"))
  local stat = vim.uv.fs_stat(candidate)
  if stat and stat.type == "file" then
    return "[[" .. target .. "]]"
  end
  if not target:find("/", 1, true) then
    local found = vim.fn.globpath(root, "**/" .. target .. ".md", false, true)
    if type(found) == "string" then
      found = found ~= "" and { found } or {}
    end
    if #found == 1 then
      local rel = vault.relative_path(found[1])
      if rel and rel ~= "" then
        local link = vim.fn.fnamemodify(rel, ":r"):gsub("\\", "/")
        return "[[" .. link .. "]]"
      end
    end
  end
  return r
end

--- Normalize `blockedBy`-style data from the CLI (strings, JSON array,
--- `{ uid = ... }` rows).
---@param raw any
---@return { uid: string }[]
function M.normalize_blocked_by(raw)
  if raw == nil then
    return {}
  end
  if type(raw) == "string" then
    local ok, decoded = pcall(vim.fn.json_decode, raw)
    if ok and type(decoded) == "table" then
      return M.normalize_blocked_by(decoded)
    end
    return { { uid = raw } }
  end
  if type(raw) ~= "table" then
    return {}
  end
  if raw.uid ~= nil then
    return { raw }
  end
  local out = {}
  for _, item in ipairs(raw) do
    if type(item) == "string" then
      out[#out + 1] = { uid = item }
    elseif type(item) == "table" and item.uid ~= nil then
      out[#out + 1] = item
    end
  end
  return out
end

---@param t string|number
---@return string
local function tag_key(t)
  local s = vim.trim(tostring(t))
  if s:sub(1, 1) == "#" then
    s = s:sub(2)
  end
  return s
end

---@param a string|number
---@param b string|number
---@return boolean
local function tags_equivalent(a, b)
  return tag_key(a) == tag_key(b)
end

--- Parse `tags`: a YAML array, or a single comma-separated scalar.
---@param raw any
---@return string[]
local function parse_tags(raw)
  local out = {}
  local function push(s)
    s = vim.trim(s)
    if s ~= "" then
      out[#out + 1] = s
    end
  end
  local function split_or_push(s)
    if s:find(",", 1, true) then
      for _, part in ipairs(vim.split(s, ",", { plain = true })) do
        push(part)
      end
    else
      push(s)
    end
  end

  if type(raw) == "table" then
    for _, t in ipairs(raw) do
      if type(t) == "string" then
        split_or_push(t)
      end
    end
  elseif type(raw) == "string" then
    split_or_push(raw)
  end
  return out
end

--- Rows for "mark blocked": optional `blockedBy` row with `{ uid = [[...]] }`
--- entries. With an empty `response` only the status is set.
---@param note_rel string
---@param response string|nil
---@param opts { blocked_property: string, status_property: string, status_value: string }
---@return table[]
function M.for_mark_blocked(note_rel, response, opts)
  if not response or response == "" then
    return {
      { name = opts.status_property, value = opts.status_value, type = "text" },
    }
  end

  local existing = M.get(note_rel, { opts.blocked_property })
  local reasons = M.normalize_blocked_by(existing[opts.blocked_property])
  table.insert(reasons, { uid = M.wiki_link_if_vault_note(response) })
  return {
    { name = opts.status_property, value = opts.status_value, type = "text" },
    { name = opts.blocked_property, value = reasons, type = "list" },
  }
end

--- Tags with `exclude_tag` removed, plus completed date and status.
---@param note_rel string
---@param opts { tags_key: string, status_key: string, status_complete: string, exclude_tag?: string, completed_date_property?: string }
---@return table[]
function M.for_mark_complete(note_rel, opts)
  local exclude_tag = opts.exclude_tag or "active"
  local completed_key = opts.completed_date_property or "completedDate"

  local note_tags = M.get(note_rel, { opts.tags_key })
  local filtered = {}
  for _, t in ipairs(parse_tags(note_tags[opts.tags_key])) do
    if not tags_equivalent(t, exclude_tag) then
      filtered[#filtered + 1] = t
    end
  end

  return {
    { name = completed_key, value = os.date "%Y-%m-%d", type = "date" },
    { name = opts.status_key, value = opts.status_complete, type = "text" },
    { name = opts.tags_key, value = filtered, type = "list" },
  }
end

--- Add `active_tag` to tags if missing; set status to in-progress.
---@param note_rel string
---@param opts { tags_key: string, status_key: string, status_in_progress: string, active_tag?: string }
---@return table[]
function M.for_mark_in_progress(note_rel, opts)
  local active_tag = opts.active_tag or "active"

  local note_tags = M.get(note_rel, { opts.tags_key })
  local tags = parse_tags(note_tags[opts.tags_key])
  local has_active = false
  for _, t in ipairs(tags) do
    if tags_equivalent(t, active_tag) then
      has_active = true
      break
    end
  end
  if not has_active then
    table.insert(tags, active_tag)
  end
  return {
    { name = opts.status_key, value = opts.status_in_progress, type = "text" },
    { name = opts.tags_key, value = tags, type = "list" },
  }
end

--- Save the buffer, write the rows through the CLI, then reload so the
--- frontmatter Obsidian wrote shows up.
---@param properties table[]
function M.update(properties)
  vim.api.nvim_buf_call(vim.api.nvim_get_current_buf(), function()
    vim.cmd "write"
  end)

  local rel = vault.current_note_path()
  if not rel then
    vim.notify("Buffer has no file path", vim.log.levels.WARN)
    return
  end

  M.set(properties, rel)
  vim.cmd "edit!"
end

return M
