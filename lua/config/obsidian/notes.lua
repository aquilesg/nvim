--- Create vault notes from the templates in `config.obsidian`, using
--- obsidian.nvim's Note API for path resolution, template substitution and
--- opening the result.
local M = {}

local vault = require "config.obsidian"

---@class config.obsidian.CreateOpts
---@field prompt_for_type boolean|nil # pick the type with `vim.ui.select`
---@field template_type string|nil # key into directories / template_names
---@field insert_link boolean|nil # insert `[[id|title]]` at the cursor first

--- Create a note for a template type key (e.g. `"WorkOncallTask"`).
---@param type_key string
function M.create_for_type(type_key)
  M.create { template_type = type_key, prompt_for_type = false }
end

---@param id string
---@param title string
local function insert_link_at_cursor(id, title)
  local text = " [[" .. id .. "|" .. title .. "]]"
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(
    string.sub(line, 1, col) .. text .. string.sub(line, col + 1)
  )
  vim.api.nvim_win_set_cursor(0, { row, col + #text })
end

---@param opts config.obsidian.CreateOpts|nil
function M.create(opts)
  opts = opts or {}

  local template_keys = vim.tbl_keys(vault.template_names)
  table.sort(template_keys)

  local function create_for_choice(choice)
    if not choice then
      return
    end
    local title = vim.fn.input { prompt = choice .. " title: " }
    if not title or title == "" then
      vim.notify("Note title cannot be empty", vim.log.levels.WARN)
      return
    end
    local id = vault.camel_case_title(title)

    local dir = vault.directories[choice]
    local template = vault.template_names[choice]
    if not dir or not template then
      vim.notify(
        "No directory or template for " .. tostring(choice),
        vim.log.levels.ERROR
      )
      return
    end

    if opts.insert_link then
      insert_link_at_cursor(id, title)
    end

    local Note = require "obsidian.note"
    local ok, note = pcall(Note.create, {
      id = id,
      title = title,
      dir = dir,
      template = template,
      verbatim = true,
    })
    if not ok then
      vim.notify("Could not create note: " .. tostring(note), vim.log.levels.ERROR)
      return
    end

    local written, err = pcall(note.write, note)
    if not written then
      vim.notify("Could not write note: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    note:open { sync = true }
  end

  if opts.prompt_for_type then
    vim.ui.select(
      template_keys,
      { prompt = "Document type" },
      create_for_choice
    )
  else
    create_for_choice(opts.template_type)
  end
end

return M
