-- TaskNotes Pomodoro control via the Obsidian CLI.
--
-- `start` runs a session for the note in the current buffer (its filename,
-- minus the extension, is used as the TaskNotes `title=`). `stop`, `pause`,
-- `resume` and `status` act on the running session and need no note.
local M = {}

local OBSIDIAN = "/opt/homebrew/bin/obsidian"
local VAULT = "brain"

M.actions = { "start", "stop", "pause", "resume", "status" }

-- Title of the note in the current buffer (filename without extension), or nil.
local function current_note_title()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil
  end
  return vim.fn.fnamemodify(name, ":t:r")
end

local function fmt_time(secs)
  secs = math.floor(tonumber(secs) or 0)
  return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- vim.json.decode turns JSON null into vim.NIL (userdata, and truthy), so
-- `foo or default` won't catch it. Fall back to `default` for nil and vim.NIL.
local function val(v, default)
  if v == nil or v == vim.NIL then
    return default
  end
  return v
end

-- Pretty-print the pomodoro state JSON as a notification.
local function notify_state(state)
  local lines = {}
  local session = val(state.currentSession)
  local header
  if state.isRunning then
    header = "󰔟 Pomodoro — Running"
  elseif session then
    header = "󰔟 Pomodoro — Paused"
  else
    header = "󰔟 Pomodoro — Stopped"
  end
  if session then
    local task = val(session.task, {})
    table.insert(lines, "Task:  " .. val(task.title, "—"))
    table.insert(
      lines,
      string.format(
        "Type:  %s (%s min)",
        val(session.type, "?"),
        val(session.plannedDuration, "?")
      )
    )
    table.insert(lines, "Left:  " .. fmt_time(state.timeRemaining))
  else
    table.insert(lines, "No active session")
    if state.timeRemaining then
      table.insert(lines, "Ready: " .. fmt_time(state.timeRemaining))
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = header })
end

-- Run a pomodoro action and show the result.
function M.pomodoro(action)
  action = action or "status"
  if not vim.tbl_contains(M.actions, action) then
    vim.notify(
      "Pomodoro: unknown action '" .. action .. "'",
      vim.log.levels.ERROR
    )
    return
  end

  local cmd = {
    OBSIDIAN,
    "tasknotes:pomodoro",
    "vault=" .. VAULT,
    "action=" .. action,
  }

  -- For `start` we act on the note in the current buffer: persist any pending
  -- edits first, then reload once the session begins so TaskNotes' frontmatter
  -- writes are reflected in the buffer.
  local reload_buf
  if action == "start" then
    local title = current_note_title()
    if not title then
      vim.notify(
        "Pomodoro: no active note to start a session for",
        vim.log.levels.WARN
      )
      return
    end
    table.insert(cmd, "title=" .. title)

    reload_buf = vim.api.nvim_get_current_buf()
    if vim.bo[reload_buf].modified then
      vim.api.nvim_buf_call(reload_buf, function()
        vim.cmd "silent write"
      end)
    end
  end

  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        local msg = res.stderr ~= "" and res.stderr or res.stdout
        vim.notify(
          "Pomodoro failed: " .. (msg or "unknown error"),
          vim.log.levels.ERROR
        )
        return
      end
      if reload_buf and vim.api.nvim_buf_is_loaded(reload_buf) then
        vim.api.nvim_buf_call(reload_buf, function()
          vim.cmd "silent edit"
        end)
      end
      local ok, state = pcall(vim.json.decode, res.stdout)
      if not ok or type(state) ~= "table" then
        vim.notify(
          "Pomodoro: could not parse output:\n" .. res.stdout,
          vim.log.levels.ERROR
        )
        return
      end
      notify_state(state)
    end)
  end)
end

-- Register the :Pomodoro command and <leader>op* keymaps.
function M.setup()
  vim.api.nvim_create_user_command("Pomodoro", function(opts)
    M.pomodoro(opts.args ~= "" and opts.args or "status")
  end, {
    nargs = "?",
    complete = function(arg_lead)
      return vim.tbl_filter(function(a)
        return a:find(arg_lead, 1, true) == 1
      end, M.actions)
    end,
    desc = "Control TaskNotes Pomodoro (start|stop|pause|resume|status)",
  })

  local map = vim.keymap.set
  local keymaps = {
    { "s", "start", "Pomodoro start (active note)" },
    { "e", "stop", "Pomodoro stop" },
    { "p", "pause", "Pomodoro pause" },
    { "r", "resume", "Pomodoro resume" },
    { "i", "status", "Pomodoro status" },
  }
  for _, km in ipairs(keymaps) do
    local suffix, action, desc = km[1], km[2], km[3]
    map("n", "<leader>op" .. suffix, function()
      M.pomodoro(action)
    end, { desc = desc })
  end
end

return M
