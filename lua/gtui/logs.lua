local http = require "gtui.http"
local state = require "gtui.state"
local ui = require "gtui.ui"

local M = {}

local LEVELS = { { "error", "DiagnosticError" }, { "warn", "DiagnosticWarn" } }
local NS = vim.api.nvim_create_namespace "gtui_logs"
local PLACEHOLDER = [[LogQL, e.g. {app="x", tng_environment="$environment"} |= "error"  (Enter to run)]]
local KEYS = {
  "<CR> / i  run (prompt) / full line (results) / focus prompt (results)",
  "<space>t  jump to trace    <space>f  live tail",
  "<space>r  refresh    <space>e  env    <space>[ <space>]  range preset",
  "<space>y <space>p  yank / paste range    <space>u <space>0  undo / reset range",
  "q  close    /  search (plain vim)",
}

local S = { rows = {}, seq = 0, tailing = false, inflight = false }

local function info()
  ui.set_info(S.res_buf, ("%d lines%s"):format(#S.rows, S.tailing and " · tailing" or ""))
end

local function svc_of(stream)
  return stream.app or stream.service_name or stream.job or ""
end

local function render()
  local buf = S.res_buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local at_end = vim.api.nvim_win_get_cursor(S.res_win)[1] >= vim.api.nvim_buf_line_count(buf)
  local lines, prefixes = {}, {}
  for i, r in ipairs(S.rows) do
    local prefix = ("%s  %-24s  "):format(ui.ts_str(r.ts), svc_of(r.stream):sub(1, 24))
    prefixes[i] = #prefix
    lines[i] = prefix .. vim.fn.strcharpart((r.line:gsub("[\r\n\t]+", " ")), 0, 400)
  end
  ui.set_lines(buf, #lines > 0 and lines or { "" })
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  for i, r in ipairs(S.rows) do
    vim.api.nvim_buf_set_extmark(buf, NS, i - 1, 0, { end_col = prefixes[i], hl_group = "Comment" })
    local low = r.line:sub(1, 200):lower()
    for _, lv in ipairs(LEVELS) do
      if low:find(lv[1], 1, true) then
        vim.api.nvim_buf_set_extmark(buf, NS, i - 1, prefixes[i], { end_col = #lines[i], hl_group = lv[2] })
        break
      end
    end
  end
  if at_end and #lines > 0 then
    vim.api.nvim_win_set_cursor(S.res_win, { #lines, 0 })
  end
  info()
end

function M.run()
  local q = S.query()
  if q == "" then
    return
  end
  local start, stop = state.window()
  S.seq = S.seq + 1
  local seq = S.seq
  http.loki_logs(state.subst(q), start * 1e9, stop * 1e9, 500, function(err, rows)
    if seq ~= S.seq then
      return
    end
    if err then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    S.rows = rows
    render()
    if vim.api.nvim_win_is_valid(S.res_win) then
      vim.api.nvim_win_set_cursor(S.res_win, { math.max(#rows, 1), 0 })
      vim.api.nvim_set_current_win(S.res_win)
    end
  end)
end

local function tail_tick()
  if not S.tailing or S.inflight or not state.range:relative() or S.query() == "" then
    return
  end
  local last = S.rows[#S.rows]
  local now = vim.uv.gettimeofday()
  local now_ns = now.sec * 1e9 + now.usec * 1e3
  S.inflight = true
  http.loki_logs(state.subst(S.query()), last and last.ts or (now_ns - 1e10), now_ns, 500, function(err, new)
    S.inflight = false
    if err then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    local seen = {}
    for i = #S.rows, 1, -1 do
      if last and S.rows[i].ts ~= last.ts then
        break
      end
      seen[S.rows[i].ts .. "\0" .. S.rows[i].line] = true
    end
    local added = false
    for _, r in ipairs(new) do
      if not seen[r.ts .. "\0" .. r.line] then
        S.rows[#S.rows + 1] = r
        added = true
      end
    end
    if added then
      S.rows = vim.list_slice(S.rows, math.max(1, #S.rows - 4999))
      render()
    end
  end)
end

local function toggle_tail()
  if not state.range:relative() then
    return vim.notify("live tail needs a relative range", vim.log.levels.WARN)
  end
  S.tailing = not S.tailing
  vim.notify("live tail " .. (S.tailing and "on" or "off"))
  info()
end

local function current()
  return S.rows[vim.api.nvim_win_get_cursor(S.res_win)[1]]
end

local function detail()
  local r = current()
  if not r then
    return
  end
  local lines = { ui.ts_str(r.ts), "" }
  local keys = vim.tbl_keys(r.stream)
  table.sort(keys)
  for _, k in ipairs(keys) do
    lines[#lines + 1] = k .. "=" .. r.stream[k]
  end
  lines[#lines + 1] = ""
  vim.list_extend(lines, vim.split(r.line, "\n", { plain = true }))
  local buf = ui.scratch("line", "gtui")
  ui.set_lines(buf, lines)
  local w, h = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = h,
    row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2),
    border = "rounded",
  })
  vim.wo[win].wrap = true
  for _, k in ipairs { "q", "<Esc>" } do
    vim.keymap.set("n", k, "<cmd>close<cr>", { buffer = buf, nowait = true })
  end
end

local function trace_id()
  local r = current()
  if not r then
    return
  end
  local low = r.line:lower()
  for _, key in ipairs { "trace_id", "traceid" } do
    local id = low:match(key .. "%W%W?%W?%W?([0-9a-f]+)")
    if id and #id >= 16 and #id <= 32 then
      return id
    end
  end
  for k, v in pairs(r.stream) do
    if k:find "trace" and v:match "^[0-9a-f]+$" and #v >= 16 and #v <= 32 then
      return v
    end
  end
end

local function jump_trace()
  local id = trace_id()
  if not id then
    return vim.notify("no trace id on this line", vim.log.levels.WARN)
  end
  local ok, traces = pcall(require, "gtui.traces")
  if not ok then
    return vim.notify("trace " .. id .. " (traces buffer not built yet)")
  end
  traces.open(id)
end

function M.explore(q)
  M.open()
  vim.cmd.stopinsert()
  S.set_query(q)
  M.run()
end

function M.open()
  if S.res_buf and vim.api.nvim_buf_is_valid(S.res_buf) then
    return vim.api.nvim_set_current_win(S.res_win)
  end
  local t = ui.query_tab { title = "logs", placeholder = PLACEHOLDER, run = M.run }
  S.res_win, S.res_buf, S.query, S.set_query = t.res_win, t.res_buf, t.query, t.set_query
  S.rows, S.tailing = {}, false

  ui.common_maps(S.res_buf, M.run)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = S.res_buf, nowait = true, desc = "gtui: " .. desc })
  end
  map("<CR>", detail, "full line")
  map("i", t.focus_prompt, "focus prompt")
  map("<space>t", jump_trace, "jump to trace")
  map("<space>f", toggle_tail, "live tail")
  map("?", function() vim.notify(table.concat(KEYS, "\n")) end, "keys")

  local timer = vim.uv.new_timer()
  timer:start(2000, 2000, vim.schedule_wrap(tail_tick))
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = S.res_buf,
    callback = function()
      timer:stop()
      timer:close()
      S.res_buf = nil
    end,
  })
  t.focus_prompt()
end

return M
