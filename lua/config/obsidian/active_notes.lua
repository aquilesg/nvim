--- Kanban board over notes that carry a tag (default `active`) or match a
--- frontmatter property, one column per status.
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
  -- Default 1s timeout is shorter than a full vault scan and yields an empty list.
  for _, loc in ipairs(search.find_tags(want, { timeout = 10000 })) do
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

local SEP = "  "
local CARD_H = 5 -- box (4 lines) + gap
local COL_HLS = { "DiagnosticInfo", "DiagnosticWarn", "DiagnosticHint", "DiagnosticOk", "DiagnosticError", "Identifier" }
local BOX = {
  plain = { "╭", "─", "╮", "│", "╰", "╯" },
  heavy = { "┏", "━", "┓", "┃", "┗", "┛" },
}

---@param s string
---@param w integer
---@return string
local function fit(s, w)
  if vim.fn.strdisplaywidth(s) > w then
    s = vim.fn.strcharpart(s, 0, w - 1) .. "…"
  end
  return s .. string.rep(" ", w - vim.fn.strdisplaywidth(s))
end

--- Group notes into status columns; empty columns are dropped.
---@param notes table[]
---@return table[]
local function build_columns(notes)
  local st = vault.status
  local defs = { st.draft, st.in_progress, st.in_review, st.review_complete, st.blocked, st.paused }
  local hidden = { [st.complete:lower()] = true, [st.abandoned:lower()] = true }
  local cols, by_status = {}, {}
  for _, name in ipairs(defs) do
    local col = { name = name, cards = {} }
    cols[#cols + 1] = col
    by_status[name:lower()] = col
  end
  local other = { name = "Needs Status", cards = {} }
  cols[#cols + 1] = other
  for _, n in ipairs(notes) do
    local key = n.status:lower()
    if not hidden[key] then
      local col = by_status[key] or other
      col.cards[#col.cards + 1] = n
    end
  end
  local out = {}
  for _, col in ipairs(cols) do
    if #col.cards > 0 then
      table.sort(col.cards, function(a, b)
        return a.id < b.id
      end)
      out[#out + 1] = col
    end
  end
  return out
end

local PROJECT_TYPES = { project_planning = true, initiative = true, epic = true }

--- Split notes into Tasks and Projects groups, dropping empty ones.
---@param notes table[]
---@return table[]
local function group_notes(notes)
  local tasks, projects = {}, {}
  for _, n in ipairs(notes) do
    local list = PROJECT_TYPES[n.doc_type] and projects or tasks
    list[#list + 1] = n
  end
  local groups = {}
  for _, g in ipairs { { name = "Tasks", notes = tasks }, { name = "Projects", notes = projects } } do
    g.cols = build_columns(g.notes)
    if #g.cols > 0 then
      groups[#groups + 1] = g
    end
  end
  return groups
end

---@param title string
---@param notes table[]
local function open_board(title, notes)
  local groups = group_notes(notes)
  if #groups == 0 then
    vim.notify("No notes to show (all completed or abandoned)", vim.log.levels.INFO)
    return
  end

  local width = math.floor(vim.o.columns * 0.9)
  local gi = 1
  local cols, colw, nlines, height

  local function layout()
    cols = groups[gi].cols
    colw = math.floor((width - (#cols - 1) * vim.fn.strdisplaywidth(SEP)) / #cols)
    local maxcards = 0
    for _, col in ipairs(cols) do
      maxcards = math.max(maxcards, #col.cards)
    end
    nlines = 2 + maxcards * CARD_H
    height = math.min(nlines, math.floor(vim.o.lines * 0.8))
  end

  local function win_title()
    local names = {}
    for i, g in ipairs(groups) do
      names[i] = i == gi and "[" .. g.name .. "]" or g.name
    end
    return " " .. title .. ": " .. table.concat(names, " ") .. " "
  end

  layout()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = win_title(),
    footer = " h/l column   j/k card   <Tab> tasks/projects   <CR> open   q close ",
    footer_pos = "center",
  })

  local ns = vim.api.nvim_create_namespace "active_notes_board"
  local sel = { col = 1, row = 1 }

  local function render()
    local lines, marks = {}, {}
    for l = 1, nlines do
      local parts, bytes = {}, 0
      for c, col in ipairs(cols) do
        local hl = COL_HLS[(c - 1) % #COL_HLS + 1]
        local text, border_hl, text_hl, pad_b = nil, nil, nil, 0
        if l == 1 then
          text, border_hl = fit(string.format("%s (%d)", col.name, #col.cards), colw), hl
        elseif l == 2 then
          text, border_hl = string.rep("━", colw), hl
        else
          local k = l - 3
          local idx, sub = math.floor(k / CARD_H) + 1, k % CARD_H
          local card = col.cards[idx]
          if card and sub < 4 then
            local selected = c == sel.col and idx == sel.row
            local b = selected and BOX.heavy or BOX.plain
            border_hl = selected and hl or "FloatBorder"
            if sub == 0 then
              text = b[1] .. string.rep(b[2], colw - 2) .. b[3]
            elseif sub == 3 then
              text = b[5] .. string.rep(b[2], colw - 2) .. b[6]
            else
              pad_b = #b[4] + 1
              text = b[4] .. " " .. fit(sub == 1 and card.id or card.doc_type, colw - 4) .. " " .. b[4]
              text_hl = sub == 2 and "Comment" or (selected and hl or "Normal")
            end
          else
            text = string.rep(" ", colw)
          end
        end
        if border_hl then
          marks[#marks + 1] = { l - 1, bytes, bytes + #text, border_hl }
        end
        if text_hl then
          marks[#marks + 1] = { l - 1, bytes + pad_b, bytes + #text - pad_b, text_hl }
        end
        parts[c] = text
        bytes = bytes + #text + #SEP
      end
      lines[l] = table.concat(parts, SEP)
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, m in ipairs(marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
    end
    local first = 3 + (sel.row - 1) * CARD_H
    local col_start = (sel.col - 1) * (colw + #SEP)
    vim.api.nvim_win_set_cursor(win, { first + 1, col_start })
  end

  local function move(dc, dr)
    sel.col = math.max(1, math.min(#cols, sel.col + dc))
    sel.row = math.max(1, math.min(#cols[sel.col].cards, sel.row + dr))
    render()
  end

  local function switch()
    if #groups < 2 then
      return
    end
    gi = gi % #groups + 1
    sel.col, sel.row = 1, 1
    layout()
    vim.api.nvim_win_set_config(win, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2) - 1,
      col = math.floor((vim.o.columns - width) / 2),
      title = win_title(),
    })
    render()
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("h", function() move(-1, 0) end)
  map("l", function() move(1, 0) end)
  map("j", function() move(0, 1) end)
  map("k", function() move(0, -1) end)
  map("<Tab>", switch)
  map("q", close)
  map("<Esc>", close)
  map("<CR>", function()
    local card = cols[sel.col].cards[sel.row]
    close()
    vim.cmd("edit " .. vim.fn.fnameescape(card.path))
  end)

  render()
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
        id = id,
        doc_type = doc_type,
        status = status,
        path = vim.fs.joinpath(root, match.rel),
      }
    end
  end

  if #display_notes == 0 then
    vim.notify("No notes to show (after template filter)", vim.log.levels.INFO)
    return
  end

  open_board("Active notes (" .. filter_label .. ")", display_notes)
end

return M
