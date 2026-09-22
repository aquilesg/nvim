--- Telescope picker over notes that carry a tag (default `active`) or match a
--- frontmatter property, showing id / document_type / status.
local M = {}

local vault = require "config.obsidian"

---@param val any
---@return string
local function to_str(val)
  if type(val) == "table" then
    return vim.inspect(val)
  elseif val == nil then
    return "N/A"
  end
  return tostring(val)
end

---@param note obsidian.Note
---@param key string
---@return any
local function note_field(note, key)
  if key == "id" then
    return note.id
  elseif key == "tags" then
    return note.tags
  elseif key == "aliases" then
    return note.aliases
  end
  return note.metadata and note.metadata[key]
end

---@param raw any
---@param expected string|number
---@return boolean
local function value_matches(raw, expected)
  if raw == nil then
    return false
  end
  local exp = vim.trim(tostring(expected))
  local function eq(v)
    local s = vim.trim(tostring(v))
    if s:sub(1, 1) == '"' and s:sub(-1, -1) == '"' then
      s = s:sub(2, -2)
    end
    return s == exp
  end
  if type(raw) == "table" then
    for _, v in ipairs(raw) do
      if eq(v) then
        return true
      end
    end
    return false
  end
  return eq(raw)
end

--- Relative `.md` paths under the vault, excluding dot directories.
---@return string[]
local function vault_md_paths()
  local root = vault.vault_dir()
  local paths = {}
  for name, ftype in vim.fs.dir(root, { depth = math.huge }) do
    if ftype == "file" and vim.endswith(name, ".md") then
      local first = name:match "^([^/]+)" or name
      if first:sub(1, 1) ~= "." then
        paths[#paths + 1] = name
      end
    end
  end
  return paths
end

--- Notes carrying `tag` exactly, as { rel_path, note } pairs.
---@param tag string
---@return table[]
local function notes_with_tag(tag)
  local search = require "obsidian.search"
  local want = tag:gsub("^#", "")
  local seen, out = {}, {}
  for _, loc in ipairs(search.find_tags(want)) do
    local key = tostring(loc.path)
    if not seen[key] and loc.tag:gsub("^#", "") == want then
      seen[key] = true
      out[#out + 1] = { rel = vault.relative_path(key), note = loc.note }
    end
  end
  return out
end

--- Notes whose frontmatter `key` equals `value` (scalar or list membership).
---@param key string
---@param value string|number
---@return table[]
local function notes_with_property(key, value)
  local Note = require "obsidian.note"
  local root = vault.vault_dir()
  local out = {}
  for _, rel in ipairs(vault_md_paths()) do
    local ok, note = pcall(Note.from_file, vim.fs.joinpath(root, rel))
    if ok and value_matches(note_field(note, key), value) then
      out[#out + 1] = { rel = rel, note = note }
    end
  end
  table.sort(out, function(a, b)
    return a.rel < b.rel
  end)
  return out
end

---@class config.obsidian.ActiveNotesOpts
---@field template_dir_name? string # skip notes under this directory
---@field tag? string # default "active"
---@field active_property? { key: string, value: string|number } # overrides tag
---@field property_keys? { status?: string, document_type?: string, id?: string }

--- Open the picker.
---@param opts config.obsidian.ActiveNotesOpts|nil
function M.open_picker(opts)
  opts = opts or {}
  if not pcall(require, "telescope.pickers") then
    vim.notify("telescope.nvim is required for this picker", vim.log.levels.WARN)
    return
  end

  local root = vault.vault_dir()
  local template_dir = opts.template_dir_name or vault.template_dir
  local pk = opts.property_keys or {}
  local status_k = pk.status or "status"
  local doc_k = pk.document_type or "document_type"
  local id_k = pk.id or "id"

  local matches, filter_label
  local ap = opts.active_property
  if ap and ap.key and ap.key ~= "" then
    filter_label = ap.key .. "=" .. tostring(ap.value)
    matches = notes_with_property(ap.key, ap.value)
  else
    local tag = opts.tag or "active"
    filter_label = "#" .. tag
    matches = notes_with_tag(tag)
  end

  if vim.tbl_isempty(matches) then
    vim.notify("No notes found for " .. filter_label, vim.log.levels.INFO)
    return
  end

  local display_notes = {}
  for _, match in ipairs(matches) do
    if not string.find(match.rel, template_dir, 1, true) then
      local id = to_str(note_field(match.note, id_k))
      local doc_type = to_str(note_field(match.note, doc_k))
      local status = to_str(note_field(match.note, status_k))
      display_notes[#display_notes + 1] = {
        display = string.format("%s -> %s -> %s", id, doc_type, status),
        ordinal = id .. " " .. doc_type .. " " .. status,
        path = vim.fs.joinpath(root, match.rel),
      }
    end
  end

  if #display_notes == 0 then
    vim.notify("No notes to show (after template filter)", vim.log.levels.INFO)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values

  pickers
    .new({}, {
      prompt_title = "Active notes (" .. filter_label .. ")",
      finder = finders.new_table {
        results = display_notes,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.ordinal,
            path = entry.path,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = conf.file_previewer {},
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.path then
            vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
          end
        end)
        return true
      end,
    })
    :find()
end

return M
