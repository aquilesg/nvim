--- Floating picker over the tasks of a note, updating checkbox status through
--- the Obsidian CLI (`tasks`/`task`).
local M = {}

local cli = require "config.obsidian.cli"
local vault = require "config.obsidian"

---@param raw table|nil
---@return table[]
local function normalize_tasks(raw)
  if type(raw) ~= "table" then
    return {}
  end
  if vim.islist(raw) then
    return raw
  end
  if raw[1] ~= nil then
    return raw
  end
  if type(raw.tasks) == "table" then
    return raw.tasks
  end
  if raw.status ~= nil and raw.text ~= nil then
    return { raw }
  end
  return {}
end

---@param tasks table[]
---@param note_rel string
---@return table[]
local function filter_for_note(tasks, note_rel)
  local want = vim.fs.normalize(note_rel):gsub("\\", "/")
  local out = {}
  for _, t in ipairs(tasks) do
    if type(t) == "table" then
      if t.file == nil then
        out[#out + 1] = t
      else
        local s = tostring(t.file):gsub("\\", "/")
        local rel = s
        if s:sub(1, 1) == "/" or s:match "^%a:/" then
          rel = vault.relative_path(s)
        end
        if rel and vim.fs.normalize(rel):gsub("\\", "/") == want then
          out[#out + 1] = t
        end
      end
    end
  end
  if #out == 0 and #tasks > 0 then
    return tasks
  end
  return out
end

---@param tasks table[]
---@param filter_char string|nil
---@return table[]
local function filter_by_status(tasks, filter_char)
  if filter_char == nil or filter_char == "" then
    return tasks
  end
  local out = {}
  for _, t in ipairs(tasks) do
    if vim.trim(tostring(t.status or "")) == vim.trim(filter_char) then
      out[#out + 1] = t
    end
  end
  return out
end

--- Strip the markdown task prefix so we do not duplicate `task.status`.
---@param line string|nil
---@return string
local function task_body(line)
  line = vim.trim(line or "")
  local body = select(2, line:match "^%-%s*%[(.-)%]%s*(.*)$")
  if body ~= nil then
    return vim.trim(body)
  end
  return line
end

---@param task table
---@return string
local function format_task(task)
  local body = task_body(task.text or "?")
  local short = vim.fn.strcharpart(body, 0, 72)
  if vim.fn.strchars(body) > 72 then
    short = short .. "…"
  end
  return string.format("- [%s] %s", tostring(task.status or " "), short)
end

local HEADER_LINES = 2

--- Floating buffer: list tasks, `<CR>` pick status, `r` refresh, `q` close.
---@param state { tasks: table[], fetch: fun(): table[] }
---@param on_status fun(task: table, refresh: fun())
local function open_popup(state, on_status)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  local function redraw()
    local lines = {
      "Obsidian tasks  —  <Enter> set status   r refresh   q close",
      string.rep("─", math.min(72, vim.o.columns - 8)),
    }
    for _, t in ipairs(state.tasks) do
      lines[#lines + 1] = format_task(t)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "markdown"
  end

  redraw()

  local height = math.max(
    3,
    math.min(HEADER_LINES + #state.tasks + 1, vim.o.lines - 4)
  )
  local width = math.min(88, vim.o.columns - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Tasks ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function refresh()
    local next_tasks = state.fetch()
    if not next_tasks or #next_tasks == 0 then
      vim.notify("No tasks left in this note.", vim.log.levels.INFO)
      close()
      return
    end
    state.tasks = next_tasks
    redraw()
    local last = HEADER_LINES + #state.tasks
    if vim.api.nvim_win_get_cursor(win)[1] > last then
      vim.api.nvim_win_set_cursor(win, { last, 0 })
    end
  end

  local function current_task()
    local idx = vim.api.nvim_win_get_cursor(win)[1] - HEADER_LINES
    if idx < 1 or idx > #state.tasks then
      return nil
    end
    return state.tasks[idx]
  end

  vim.keymap.set("n", "<CR>", function()
    local t = current_task()
    if t then
      on_status(t, refresh)
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "r", refresh, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })

  vim.api.nvim_win_set_cursor(win, { HEADER_LINES + 1, 0 })
end

---@param note_rel string
---@param line_nr integer|string
---@param status_key string
---@return boolean
local function update_task_status(note_rel, line_nr, status_key)
  local cmd = string.format(
    'task path="%s" line=%s status="%s"',
    cli.escape(note_rel),
    tostring(tonumber(line_nr) or line_nr),
    cli.escape(status_key)
  )
  if cli.run_text(cmd) == nil then
    cli.log("update_task_status: task command failed: " .. cmd .. "\n")
    return false
  end
  return true
end

--- Pick a task in the note, then a new checkbox status, and update via CLI.
---@param note_path string|nil # vault-relative; defaults to the current buffer
---@param requested_status string|nil # only tasks whose status matches
---@param opts { statuses?: { key: string, label: string }[] }|nil
function M.pick(note_path, requested_status, opts)
  opts = opts or {}

  local target = note_path
  if not target or target == "" then
    target = vault.current_note_path()
  end
  if not target then
    vim.notify("Buffer has no file path", vim.log.levels.WARN)
    return
  end

  local task_cmd =
    string.format('tasks path="%s" format="json"', cli.escape(target))
  if requested_status and requested_status ~= "" then
    task_cmd = task_cmd
      .. string.format(' status="%s"', cli.escape(requested_status))
  end

  local function fetch()
    local tasks = normalize_tasks(cli.run_json(task_cmd))
    tasks = filter_for_note(tasks, target)
    return filter_by_status(tasks, requested_status)
  end

  local tasks = fetch()
  if #tasks == 0 then
    vim.notify("No tasks found for this note.", vim.log.levels.INFO)
    return
  end

  local note_abs =
    vim.fs.normalize(vim.fs.joinpath(vault.vault_dir(), target))

  -- `:edit!` rather than `:checktime`, which can wait for the next redraw.
  local function reload_note_buffers()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" then
        local name = vim.api.nvim_buf_get_name(b)
        if name ~= "" and vim.fs.normalize(name) == note_abs then
          if vim.bo[b].modified then
            vim.notify(
              "Note has unsaved changes; skipped reload after task update.",
              vim.log.levels.WARN
            )
          else
            vim.api.nvim_buf_call(b, function()
              vim.cmd.edit { bang = true }
            end)
          end
        end
      end
    end
    vim.cmd.redraw()
  end

  local statuses = opts.statuses or vault.task_statuses

  local function pick_status(task, refresh_popup)
    vim.ui.select(statuses, {
      prompt = "New status",
      format_item = function(row)
        return row.label
      end,
    }, function(choice)
      if choice == nil then
        return
      end
      if update_task_status(target, task.line, choice.key) then
        vim.notify("Task updated.", vim.log.levels.INFO)
        reload_note_buffers()
        if refresh_popup then
          refresh_popup()
        end
      else
        vim.notify(
          "Could not update task (see the obsidian log).",
          vim.log.levels.ERROR
        )
      end
    end)
  end

  open_popup({ tasks = tasks, fetch = fetch }, pick_status)
end

return M
