local config = require "gtui.config"
local http = require "gtui.http"
local state = require "gtui.state"
local canvas = require "gtui.canvas"
local pick = require "gtui.pick"
local ui = require "gtui.ui"

local M = {}

local NS = vim.api.nvim_create_namespace "gtui_dash"
local BODY = 14
local LOCAL_DIR = debug.getinfo(1, "S").source:sub(2):match "(.*)/" .. "/dashboards"
local GRAFANA_TYPES = {
  timeseries = "timeseries", graph = "timeseries", trend = "timeseries",
  stat = "stat", singlestat = "stat", gauge = "stat", bargauge = "stat",
  table = "table", ["table-old"] = "table",
  logs = "logs",
}

local D -- the open dashboard: { title, vars, panels, buf, win, gen }

-- model

function M.list_local()
  local names = {}
  for _, f in ipairs(vim.fn.glob(LOCAL_DIR .. "/*.lua", false, true)) do
    names[#names + 1] = vim.fn.fnamemodify(f, ":t:r")
  end
  table.sort(names)
  return names
end

function M.load_local(name)
  local t = dofile(LOCAL_DIR .. "/" .. name .. ".lua")
  local panels = {}
  for _, p in ipairs(t.panels or {}) do
    panels[#panels + 1] = {
      title = p.title, type = p.type or "timeseries", ds = p.ds or "mimir",
      exprs = p.exprs or { p.expr }, thresholds = p.thresholds, span = p.span,
    }
  end
  return { title = t.title or name, vars = t.vars or {}, panels = panels }
end

local function parse_ref(ref)
  ref = vim.trim(ref)
  if not vim.startswith(ref, "http") then
    return ref, {}
  end
  local overrides = {}
  for k, v in ref:gmatch "[?&]var%-([^=&]+)=([^&]*)" do
    v = vim.uri_decode(v)
    overrides[k] = overrides[k] and (overrides[k] .. "," .. v) or v
  end
  return ref:match "/d/([^/?#]+)", overrides
end

local function var_value(cur)
  if type(cur) == "table" then
    if vim.tbl_contains(cur, "$__all") then
      return ".*"
    end
    return #cur == 1 and cur[1] or ("(" .. table.concat(cur, "|") .. ")")
  end
  return cur == "$__all" and ".*" or tostring(cur or "")
end

-- saved dashboards often have no current value; Grafana then uses the first option
local function default_value(v)
  local cur = (v.current or {}).value
  if cur ~= nil and cur ~= "" then
    return var_value(cur)
  end
  local opt = (v.options or {})[1]
  if opt and opt.value then
    return var_value(opt.value)
  end
  if v.type == "custom" and type(v.query) == "string" then
    local first = vim.trim(v.query:match "^[^,]+" or "")
    if first ~= "" then
      return first
    end
  end
  return ".*"
end

local function ds_kind(ds)
  local t = (type(ds) == "table" and ds.type or tostring(ds or "")):lower()
  if t:find "loki" then
    return "loki"
  end
  return (t:find "prom" or t:find "mimir") and "mimir" or ""
end

local function flatten(panels, out)
  for _, p in ipairs(panels or {}) do
    if p.type == "row" then
      flatten(p.panels, out)
    else
      out[#out + 1] = p
    end
  end
  return out
end

function M.load_grafana(ref, cb)
  local uid, overrides = parse_ref(ref)
  if not uid then
    return cb "no dashboard uid in that reference"
  end
  http.grafana("/api/dashboards/uid/" .. uid, nil, function(err, d)
    if err then
      return cb(err)
    end
    local js = d.dashboard
    local vars = {}
    for _, v in ipairs((js.templating or {}).list or {}) do
      vars[v.name] = default_value(v)
    end
    vars = vim.tbl_extend("force", vars, overrides)
    local panels = {}
    for _, p in ipairs(flatten(js.panels, {})) do
      local exprs = {}
      for _, t in ipairs(p.targets or {}) do
        if t.expr then
          exprs[#exprs + 1] = t.expr
        end
      end
      panels[#panels + 1] = {
        title = p.title or "", type = GRAFANA_TYPES[p.type] or p.type,
        ds = ds_kind(p.datasource), exprs = exprs,
        span = ((p.gridPos or {}).w or 12) >= 16 and 2 or 1,
      }
    end
    cb(nil, { title = js.title or uid, vars = vars, panels = panels })
  end)
end

-- fetching

local function fetch(p, cb)
  local start, stop = state.window()
  local exprs = {}
  for _, e in ipairs(p.exprs) do
    exprs[#exprs + 1] = state.subst(e, D.vars)
  end
  if #exprs == 0 then
    return cb "no expression"
  end
  if p.type == "logs" then
    return http.loki_logs(exprs[1], start * 1e9, stop * 1e9, 200, cb)
  end
  if p.type ~= "timeseries" and p.type ~= "stat" and p.type ~= "table" then
    return cb("unsupported panel type: " .. p.type)
  end
  local results, pending, failed = {}, #exprs, false
  for i, e in ipairs(exprs) do
    local function done(err, res)
      if failed then
        return
      end
      if err then
        failed = true
        return cb(err)
      end
      results[i] = res
      pending = pending - 1
      if pending == 0 then
        local flat = {}
        for _, r in ipairs(results) do
          vim.list_extend(flat, r)
        end
        cb(nil, flat)
      end
    end
    if p.type == "timeseries" then
      http.series(p.ds, e, start, stop, done)
    else
      http.instant(p.ds, e, stop, done)
    end
  end
end

-- rendering: every panel is a fixed block of BODY lines under a header line

local function pad(lines, hls, height)
  while #lines < height do
    lines[#lines + 1] = ""
  end
  for i = #lines, height + 1, -1 do
    lines[i] = nil
  end
  return lines, hls
end

local function metric_label(m)
  local vals = {}
  for k, v in pairs(m) do
    if k ~= "__name__" then
      vals[#vals + 1] = v
    end
  end
  table.sort(vals)
  return m.__name__ or (#vals > 0 and table.concat(vals, ",")) or "value"
end

local function render_body(p, width, height)
  if p.err then
    return pad({ p.err }, { { row = 0, col = 0, end_col = #p.err, group = "DiagnosticError" } }, height)
  end
  if not p.data then
    return pad({ "loading..." }, { { row = 0, col = 0, end_col = 10, group = "Comment" } }, height)
  end
  local lines, hls = {}, {}
  if p.type == "timeseries" then
    local legend = math.min(#p.data, 4)
    local out = canvas.render(p.data, {
      width = math.max(20, width - canvas.gutter),
      height = math.max(4, height - 2 - legend - (#p.data > 4 and 1 or 0)),
      legend_max = 4, frame = false,
    })
    lines, hls = out.lines, out.hls
  elseif p.type == "stat" then
    if #p.data == 0 then
      lines[1] = "no data"
    end
    for i = 1, math.min(#p.data, 6) do
      local v = ("%.4g"):format(p.data[i].value)
      lines[i] = ("%-12s  %s"):format(v, metric_label(p.data[i].metric):sub(1, 50))
      local th, val = p.thresholds, p.data[i].value
      local group = "Title"
      if th then
        group = (th.crit and val >= th.crit and "DiagnosticError")
          or (th.warn and val >= th.warn and "DiagnosticWarn") or "DiagnosticOk"
      end
      hls[#hls + 1] = { row = i - 1, col = 0, end_col = #v, group = group }
    end
  elseif p.type == "table" then
    local keyset = {}
    for _, r in ipairs(p.data) do
      for k in pairs(r.metric) do
        keyset[k] = true
      end
    end
    local keys = vim.tbl_keys(keyset)
    table.sort(keys)
    local rows = { vim.list_extend(vim.deepcopy(keys), { "value" }) }
    for i = 1, math.min(#p.data, height - 2) do
      local row = {}
      for _, k in ipairs(keys) do
        row[#row + 1] = p.data[i].metric[k] or ""
      end
      row[#row + 1] = ("%.4g"):format(p.data[i].value)
      rows[#rows + 1] = row
    end
    local widths = {}
    for _, row in ipairs(rows) do
      for c, cell in ipairs(row) do
        widths[c] = math.min(30, math.max(widths[c] or 0, #cell))
      end
    end
    for i, row in ipairs(rows) do
      local cells = {}
      for c, cell in ipairs(row) do
        cells[c] = ("%-" .. widths[c] .. "s"):format(cell:sub(1, 30))
      end
      lines[i] = table.concat(cells, "  ")
    end
    hls[1] = { row = 0, col = 0, end_col = #lines[1], group = "Title" }
    if #p.data > height - 2 then
      lines[#lines + 1] = ("... %d more rows"):format(#p.data - (height - 2))
    end
  elseif p.type == "logs" then
    for i = math.max(1, #p.data - height + 1), #p.data do
      local r = p.data[i]
      local prefix = ui.ts_str(r.ts) .. "  "
      lines[#lines + 1] = prefix .. vim.fn.strcharpart((r.line:gsub("[\r\n\t]+", " ")), 0, 300)
      hls[#hls + 1] = { row = #lines - 1, col = 0, end_col = #prefix, group = "Comment" }
    end
  end
  return pad(lines, hls, height)
end

local BLOCK = BODY + 3
local BORDER = "FloatBorder"

local function dw(text)
  return vim.fn.strdisplaywidth(text)
end

-- body wrapped in a rounded box with the title in the top border
local function card(p, i, width, height)
  local inner = width - 4
  local body, bh = render_body(p, inner, height)
  local title = ("%d. %s"):format(i, p.title)
  local max_title = math.max(8, width - #p.type - 8)
  if dw(title) > max_title then
    title = vim.fn.strcharpart(title, 0, max_title - 1) .. "…"
  end
  local fill = math.max(1, width - dw(title) - #p.type - 8)
  local top = "╭─ " .. title .. " " .. string.rep("─", fill) .. " " .. p.type .. " ─╮"
  local lines = { top }
  local hls = {
    { row = 0, col = 0, end_col = #top, group = BORDER },
    { row = 0, col = 7, end_col = 7 + #title, group = "Title" },
    { row = 0, col = 7 + #title + 1 + #"─" * fill + 1, end_col = #top - #"─╮" - 1, group = "Comment" },
  }
  local edge = #"│ "
  for r, line in ipairs(body) do
    local t = vim.fn.strcharpart(line, 0, inner)
    local fill_n = inner - dw(t)
    lines[#lines + 1] = "│ " .. t .. string.rep(" ", fill_n) .. " │"
    hls[#hls + 1] = { row = r, col = 0, end_col = #"│", group = BORDER }
    local right = edge + #t + fill_n + 1
    hls[#hls + 1] = { row = r, col = right, end_col = right + #"│", group = BORDER }
  end
  for _, h in ipairs(bh) do
    hls[#hls + 1] = {
      row = h.row + 1, col = h.col + edge,
      end_col = math.min(h.end_col, h.col + #(body[h.row + 1] and vim.fn.strcharpart(body[h.row + 1], 0, inner) or "")) + edge,
      group = h.group,
    }
  end
  lines[#lines + 1] = "╰" .. string.rep("─", width - 2) .. "╯"
  hls[#hls + 1] = { row = #lines - 1, col = 0, end_col = #lines[#lines], group = BORDER }
  return lines, hls
end

-- rows of panel indexes: wide panels get a row, the rest pair up when the window is wide enough
local function layout(panels, width)
  local rows, i = {}, 1
  while i <= #panels do
    local p, q = panels[i], panels[i + 1]
    if width >= 100 and p.span ~= 2 and q and q.span ~= 2 then
      rows[#rows + 1] = { i, i + 1 }
      i = i + 2
    else
      rows[#rows + 1] = { i }
      i = i + 1
    end
  end
  return rows
end

local function draw()
  if not (D and D.buf and vim.api.nvim_buf_is_valid(D.buf)) then
    return
  end
  local width = vim.api.nvim_win_get_width(D.win)
  D.rows = layout(D.panels, width)
  local lines, hls = {}, {}
  local function add(row0, hs, shift)
    for _, h in ipairs(hs) do
      local by = shift and shift[h.row + 1] or 0
      hls[#hls + 1] = { row = h.row + row0, col = h.col + by, end_col = h.end_col + by, group = h.group }
    end
  end
  for _, row in ipairs(D.rows) do
    local row0 = #lines
    if #row == 1 then
      local p = D.panels[row[1]]
      local cl, ch = card(p, row[1], width, BODY)
      p.line, p.col = row0 + 1, 0
      vim.list_extend(lines, cl)
      add(row0, ch)
    else
      local wl = math.floor((width - 1) / 2)
      local left, lh = card(D.panels[row[1]], row[1], wl, BODY)
      local right, rh = card(D.panels[row[2]], row[2], width - 1 - wl, BODY)
      row.wl = wl
      local shift = {}
      for k = 1, #left do
        lines[#lines + 1] = left[k] .. " " .. right[k]
        shift[k] = #left[k] + 1
      end
      D.panels[row[1]].line, D.panels[row[1]].col = row0 + 1, 0
      D.panels[row[2]].line, D.panels[row[2]].col = row0 + 1, shift[1]
      add(row0, lh)
      add(row0, rh, shift)
    end
    lines[#lines + 1] = ""
  end
  ui.set_lines(D.buf, lines)
  vim.api.nvim_buf_clear_namespace(D.buf, NS, 0, -1)
  ui.apply_hls(D.buf, NS, hls)
  ui.set_info(D.buf, ("%d panels"):format(#D.panels))
end

local function refresh()
  if not D then
    return
  end
  D.gen = D.gen + 1
  local gen = D.gen
  for _, p in ipairs(D.panels) do
    p.data, p.err = nil, nil
    fetch(p, function(err, data)
      if not D or gen ~= D.gen then
        return
      end
      p.err, p.data = err, data
      draw()
    end)
  end
  draw()
end

local function panel_at_cursor()
  local row = vim.api.nvim_win_get_cursor(D.win)[1]
  local r = D.rows[math.floor((row - 1) / BLOCK) + 1]
  if not r then
    return nil
  end
  local idx = r[1]
  if #r == 2 and vim.fn.virtcol "." > r.wl then
    idx = r[2]
  end
  return D.panels[idx], idx
end

-- opens the panel's first query in the Metrics or Logs tab
local function explore(p)
  if not p then
    return
  end
  if #p.exprs > 1 then
    vim.notify(("panel has %d queries, using the first"):format(#p.exprs))
  end
  local q = state.subst(p.exprs[1], D and D.vars or {}, true)
  require(p.type == "logs" and "gtui.logs" or p.ds == "loki" and "gtui.logs" or "gtui.metrics").explore(q)
end

local function zoom()
  local p, idx = panel_at_cursor()
  if not p then
    return
  end
  vim.cmd.tabnew()
  local win = vim.api.nvim_get_current_win()
  local buf = ui.scratch(p.title)
  vim.api.nvim_win_set_buf(win, buf)
  ui.use_bar(win)
  vim.wo[win].wrap = false
  local lines, hls = card(p, idx, vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win) - 3)
  ui.set_lines(buf, lines)
  ui.apply_hls(buf, NS, hls)
  vim.keymap.set("n", "q", vim.cmd.tabclose, { buffer = buf, nowait = true, desc = "gtui: close tab" })
  vim.keymap.set("n", "gd", function() explore(p) end, { buffer = buf, desc = "gtui: explore panel" })
end

local function jump(delta)
  local _, idx = panel_at_cursor()
  local p = D.panels[math.max(1, math.min(#D.panels, (idx or 1) + delta))]
  if p and p.line then
    vim.api.nvim_win_set_cursor(D.win, { p.line, p.col })
  end
end

function M.show(dash)
  vim.cmd.tabnew()
  local win = vim.api.nvim_get_current_win()
  local buf = ui.scratch(dash.title)
  vim.api.nvim_win_set_buf(win, buf)
  ui.use_bar(win)
  vim.wo[win].wrap = false
  D = vim.tbl_extend("force", dash, { buf = buf, win = win, gen = 0 })

  ui.common_maps(buf, refresh)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = "gtui: " .. desc })
  end
  map("<CR>", zoom, "zoom panel")
  map("gd", function() explore((panel_at_cursor())) end, "explore panel in Metrics/Logs")
  map("]]", function() jump(1) end, "next panel")
  map("[[", function() jump(-1) end, "previous panel")

  local group = vim.api.nvim_create_augroup("gtui_dash", { clear = true })
  vim.api.nvim_create_autocmd("WinResized", { group = group, callback = draw })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      D = nil
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  refresh()
end

-- picker

local function open_remote(ref)
  M.load_grafana(ref, function(err, dash)
    if err then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    M.show(dash)
  end)
end

local function preview_dash(dash)
  local lines = { "# " .. dash.title, "" }
  local names = vim.tbl_keys(dash.vars)
  table.sort(names)
  for _, k in ipairs(names) do
    lines[#lines + 1] = ("- %s = %s"):format(k, dash.vars[k])
  end
  if #names > 0 then
    lines[#lines + 1] = ""
  end
  for i, p in ipairs(dash.panels) do
    lines[#lines + 1] = ("## %d. %s  [%s%s]"):format(i, p.title, p.type, p.ds ~= "" and (", " .. p.ds) or "")
    for _, e in ipairs(p.exprs) do
      lines[#lines + 1] = "    " .. e
    end
    lines[#lines + 1] = ""
  end
  return lines
end

local cache = { at = 0 }

-- cb(items) with every Grafana dashboard; empty without a token or on error
local function remote_items(cb)
  if not config.grafana_token then
    return cb {}
  end
  if cache.items and os.time() - cache.at < 600 then
    return cb(cache.items)
  end
  vim.notify "loading Grafana dashboards..."
  http.grafana("/api/search", { { "type", "dash-db" }, { "limit", 5000 } }, function(err, found)
    if err then
      vim.notify("Grafana search failed: " .. err, vim.log.levels.ERROR)
      return cb {}
    end
    local items = {}
    for _, d in ipairs(found) do
      local folder, tags = d.folderTitle or "General", d.tags or {}
      items[#items + 1] = {
        kind = "remote", uid = d.uid, folder = folder, title = d.title, tags = tags, url = d.url,
        label = ("%s / %s%s"):format(folder, d.title, #tags > 0 and ("  #" .. table.concat(tags, " #")) or ""),
      }
    end
    cache = { at = os.time(), items = items }
    cb(items)
  end)
end

function M.open()
  remote_items(function(remote)
    local items = {}
    for _, n in ipairs(M.list_local()) do
      items[#items + 1] = { label = "local / " .. n, kind = "local", name = n }
    end
    vim.list_extend(items, remote)
    pick.select(items, {
      prompt = "gtui dashboards (paste a Grafana URL + Enter to open it)",
      format = function(i) return i.label end,
      on_url = function(url)
        if config.grafana_token then
          open_remote(url)
        else
          vim.notify("set GRAFANA_API_KEY to open Grafana dashboards", vim.log.levels.WARN)
        end
      end,
      preview = function(i)
        if i.kind == "remote" then
          return {
            "# " .. i.title, "",
            "- folder: " .. i.folder,
            "- uid: " .. i.uid,
            "- tags: " .. table.concat(i.tags, ", "),
            "- " .. config.grafana .. (i.url or ""),
          }
        end
        local ok, dash = pcall(M.load_local, i.name)
        return ok and preview_dash(dash) or { "error loading " .. i.name, tostring(dash) }
      end,
    }, function(item)
      if not item then
        return
      end
      if item.kind == "remote" then
        return open_remote(item.uid)
      end
      local ok, dash = pcall(M.load_local, item.name)
      if not ok then
        return vim.notify(item.name .. ": " .. tostring(dash), vim.log.levels.ERROR)
      end
      M.show(dash)
    end)
  end)
end

return M
