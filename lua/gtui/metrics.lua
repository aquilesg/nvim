local http = require "gtui.http"
local state = require "gtui.state"
local timerange = require "gtui.timerange"
local canvas = require "gtui.canvas"
local ui = require "gtui.ui"

local M = {}

local NS = vim.api.nvim_create_namespace "gtui_metrics"
local PLACEHOLDER = "PromQL (Mimir)  (Enter to run)"
local S = { series = {}, sel = {}, legend = true, seq = 0 }

local function valid()
  return S.res_buf and vim.api.nvim_buf_is_valid(S.res_buf) and vim.api.nvim_win_is_valid(S.res_win)
end

local function redraw()
  if not valid() then
    return
  end
  local legend = S.legend and math.min(#S.series, 8) or 0
  local width = math.max(20, vim.api.nvim_win_get_width(S.res_win) - canvas.gutter - 1)
  local height = math.max(5, vim.api.nvim_win_get_height(S.res_win) - 3 - legend - (#S.series > 8 and S.legend and 1 or 0) - 1)
  local marks = {}
  if S.sel.a then
    marks[#marks + 1] = { S.sel.a, "DiagnosticWarn" }
  end
  if S.sel.b then
    marks[#marks + 1] = { S.sel.b, "DiagnosticError" }
  end
  local out = canvas.render(S.series, { width = width, height = height, marks = marks, legend_max = S.legend and 8 or 0 })
  S.out = out
  ui.set_lines(S.res_buf, out.lines)
  vim.api.nvim_buf_clear_namespace(S.res_buf, NS, 0, -1)
  ui.apply_hls(S.res_buf, NS, out.hls)
  ui.set_info(S.res_buf, ("%d series"):format(#S.series))
end

function M.run()
  local q = S.query()
  if q == "" then
    return
  end
  local start, stop = state.window()
  S.seq = S.seq + 1
  local seq = S.seq
  http.series("mimir", state.subst(q), start, stop, function(err, series)
    if seq ~= S.seq then
      return
    end
    if err then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    S.series, S.sel = series, {}
    redraw()
    vim.notify(#series .. " series")
    if valid() then
      vim.api.nvim_set_current_win(S.res_win)
    end
  end)
end

local function cursor_frac()
  if not (S.out and S.out.t0) then
    return nil
  end
  local c = vim.fn.virtcol "." - canvas.gutter
  c = math.max(1, math.min(S.out.width, c))
  return S.out.width > 1 and (c - 1) / (S.out.width - 1) or 0
end

local function mark()
  local f = cursor_frac()
  if not f then
    return vim.notify("run a query first", vim.log.levels.WARN)
  end
  if not S.sel.a or S.sel.b then
    S.sel = { a = f }
    vim.notify("anchor set: move, <space>v again for the other edge, <CR> to zoom")
  else
    S.sel.b = f
    vim.notify("<CR> to zoom, <Esc> to cancel")
  end
  redraw()
end

local function zoom()
  if not (S.sel.a and S.sel.b) then
    return vim.notify("set two edges with <space>v first", vim.log.levels.WARN)
  end
  local lo, hi = math.min(S.sel.a, S.sel.b), math.max(S.sel.a, S.sel.b)
  if hi - lo < 0.005 then
    return vim.notify("edges are too close together", vim.log.levels.WARN)
  end
  local t0, t1 = S.out.t0, S.out.t1
  local function ms(f)
    return string.format("%.0f", (t0 + f * (t1 - t0)) * 1000)
  end
  S.sel = {}
  state.set_range(timerange.new(ms(lo), ms(hi)))
  M.run()
end

function M.explore(q)
  M.open()
  vim.cmd.stopinsert()
  S.set_query(q)
  M.run()
end

function M.open()
  if valid() then
    return vim.api.nvim_set_current_win(S.res_win)
  end
  local t = ui.query_tab { title = "metrics", placeholder = PLACEHOLDER, run = M.run }
  S.res_win, S.res_buf, S.query, S.set_query = t.res_win, t.res_buf, t.query, t.set_query
  S.series, S.sel, S.out = {}, {}, nil
  vim.wo[S.res_win].wrap = false

  ui.common_maps(S.res_buf, M.run)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = S.res_buf, nowait = true, desc = "gtui: " .. desc })
  end
  map("i", t.focus_prompt, "focus prompt")
  map("<space>v", mark, "select range edge")
  map("<CR>", zoom, "zoom to selection")
  map("<Esc>", function()
    S.sel = {}
    redraw()
  end, "cancel selection")
  map("<space>l", function()
    S.legend = not S.legend
    redraw()
  end, "toggle legend")

  local group = vim.api.nvim_create_augroup("gtui_metrics", { clear = true })
  vim.api.nvim_create_autocmd("WinResized", { group = group, callback = redraw })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = S.res_buf,
    callback = function()
      S.res_buf = nil
      vim.api.nvim_del_augroup_by_id(group)
    end,
  })
  t.focus_prompt()
end

return M
