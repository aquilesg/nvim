-- TaskNotes Pomodoro control via the Obsidian CLI.
--
-- `start` runs a session for an open note (its filename, minus the extension,
-- is used as the TaskNotes `title=`). It scans every loaded buffer for notes;
-- with one it uses that note, with several it prompts you to pick. `stop`,
-- `pause`, `resume` and `status` act on the running session and need no note.
local M = {}

local is_in_brain = require("config.obsidian.vault").is_in_brain

local OBSIDIAN = "/opt/homebrew/bin/obsidian"
local VAULT = "brain"

-- How often the background poll resyncs the cached state with the CLI. We count
-- down locally between polls, so this only needs to be frequent enough to catch
-- session transitions (work -> break) started outside Neovim.
local POLL_MS = 15000

M.actions = { "start", "stop", "pause", "resume", "status" }

-- Cached session state for the statusline, so the lualine component can render
-- without shelling out to the Obsidian CLI on every redraw. `remaining` is the
-- seconds left as of `synced_at`; `M.remaining_now()` counts down from there.
M.cache = {
  status = "stopped", -- "running" | "paused" | "stopped"
  remaining = 0,
  synced_at = 0,
  type = nil,
  alerted = false, -- whether the "1 minute left" warning has fired this session
}

-- TaskNotes title for a buffer: its filename without the extension.
local function buf_title(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r")
end

-- Loaded, listed buffers backed by a markdown note inside the brain vault.
local function note_buffers()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and name:match "%.md$" and is_in_brain(buf) then
        table.insert(bufs, buf)
      end
    end
  end
  return bufs
end

-- Resolve the note buffer to start a session for and pass it to `cb`. With a
-- single open note we use it directly; with several we prompt. `cb` receives
-- nil when there are no notes open or the prompt is dismissed.
local function pick_note_buffer(cb)
  local bufs = note_buffers()
  if #bufs <= 1 then
    cb(bufs[1])
    return
  end
  vim.ui.select(bufs, {
    prompt = "Pomodoro: select a note",
    format_item = buf_title,
  }, cb)
end

local function fmt_time(secs)
  secs = math.floor(tonumber(secs) or 0)
  return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- Coarse minute display for the statusline, rounded up so it changes only once
-- a minute rather than flickering every second (e.g. 25:00 and 24:01 -> "25m").
local function fmt_minutes(secs)
  secs = math.floor(tonumber(secs) or 0)
  return string.format("%dm", math.ceil(secs / 60))
end

-- vim.json.decode turns JSON null into vim.NIL (userdata, and truthy), so
-- `foo or default` won't catch it. Fall back to `default` for nil and vim.NIL.
local function val(v, default)
  if v == nil or v == vim.NIL then
    return default
  end
  return v
end

-- One-shot timer that fires the "1 minute left" warning. Re-armed on every
-- cache update, so pauses/resumes and sessions started outside Neovim are
-- tracked; only running sessions with more than a minute left get a timer.
local alert_timer

local function clear_alert_timer()
  if alert_timer then
    alert_timer:stop()
    alert_timer:close()
    alert_timer = nil
  end
end

local function fire_alert()
  M.cache.alerted = true
  local what = M.cache.type and (M.cache.type .. " ") or ""
  vim.notify(
    "1 minute left in your " .. what .. "session",
    vim.log.levels.WARN,
    { title = "󰔟 Pomodoro" }
  )
end

-- (Re)arm the warning for when the running session hits one minute remaining.
local function schedule_alert()
  clear_alert_timer()
  if M.cache.status ~= "running" or M.cache.alerted then
    return
  end
  local lead = M.remaining_now() - 60
  if lead <= 0 then
    if M.remaining_now() > 0 then
      fire_alert()
    end
    return
  end
  alert_timer = vim.uv.new_timer()
  if alert_timer then
    alert_timer:start(
      lead * 1000,
      0,
      vim.schedule_wrap(function()
        if M.cache.status == "running" and not M.cache.alerted then
          fire_alert()
        end
      end)
    )
  end
end

-- Refresh the statusline cache from a decoded pomodoro state.
local function update_cache(state)
  local session = val(state.currentSession)
  if state.isRunning then
    M.cache.status = "running"
  elseif session then
    M.cache.status = "paused"
  else
    M.cache.status = "stopped"
  end
  M.cache.remaining = math.floor(tonumber(val(state.timeRemaining, 0)) or 0)
  M.cache.synced_at = os.time()
  M.cache.type = session and val(session.type, nil) or nil
  -- A fresh session (more than a minute on the clock) re-arms the warning;
  -- this also covers work -> break transitions, which reset the timer.
  if M.cache.remaining > 60 then
    M.cache.alerted = false
  end
  schedule_alert()
end

-- Seconds left right now: count down locally from the last sync while running.
function M.remaining_now()
  if M.cache.status == "running" then
    local left = M.cache.remaining - (os.time() - M.cache.synced_at)
    return left > 0 and left or 0
  end
  return M.cache.remaining
end

-- Statusline string for the lualine component; empty when no active session.
function M.statusline()
  if M.cache.status == "stopped" then
    return ""
  end
  local icon = M.cache.status == "running" and "󰔟" or "󰏤"
  local label = M.cache.type and (" " .. M.cache.type) or ""
  return string.format("%s %s%s", icon, fmt_minutes(M.remaining_now()), label)
end

-- Refresh the cache from the CLI without any notification (background poll).
local function refresh_cache()
  vim.system({
    OBSIDIAN,
    "tasknotes:pomodoro",
    "vault=" .. VAULT,
    "action=status",
  }, { text = true }, function(res)
    if res.code ~= 0 then
      return
    end
    vim.schedule(function()
      local ok, state = pcall(vim.json.decode, res.stdout)
      if ok and type(state) == "table" then
        update_cache(state)
      end
    end)
  end)
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

-- Run a pomodoro action via the CLI and show the result. `title` scopes a
-- `start` to a note; `reload_buf`, if given, is reloaded once the session
-- begins so TaskNotes' frontmatter writes show up in the buffer.
local function run_action(action, title, reload_buf)
  local cmd = {
    OBSIDIAN,
    "tasknotes:pomodoro",
    "vault=" .. VAULT,
    "action=" .. action,
  }
  if title then
    table.insert(cmd, "title=" .. title)
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
      update_cache(state)
      notify_state(state)
    end)
  end)
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

  -- `start` acts on an open note, chosen from the loaded buffers (prompting if
  -- there is more than one); the other actions need no note. Resolve the note
  -- first, then run the command with the chosen title.
  if action ~= "start" then
    run_action(action)
    return
  end

  pick_note_buffer(function(buf)
    if not buf then
      vim.notify(
        "Pomodoro: no note open to start a session for",
        vim.log.levels.WARN
      )
      return
    end
    -- Persist any pending edits first so the session starts from what's on
    -- screen; run_action reloads the buffer afterward.
    if vim.bo[buf].modified then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd "silent write"
      end)
    end
    run_action(action, buf_title(buf), buf)
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
    { "s", "start", "Pomodoro start (open note)" },
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

  -- Keep the statusline roughly in sync with the real session. We count down
  -- locally between polls, so a coarse interval is enough.
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(POLL_MS, POLL_MS, vim.schedule_wrap(refresh_cache))
  end
end

return M
