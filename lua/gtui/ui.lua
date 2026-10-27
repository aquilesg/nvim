local state = require "gtui.state"
local timerange = require "gtui.timerange"

local M = {}

local bars = {}

local ENV_SRC = { production = "DiagnosticError", uat = "DiagnosticWarn", integration3 = "DiagnosticOk" }

local function hl_attr(name, attr)
  local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and h[attr] or nil
end

local function setup_hl()
  local bar_bg = hl_attr("WinBar", "bg") or hl_attr("Normal", "bg")
  local normal_bg = hl_attr("Normal", "bg") or 0x1e1e1e
  vim.api.nvim_set_hl(0, "GtuiBar", { fg = hl_attr("WinBar", "fg") or hl_attr("Normal", "fg"), bg = bar_bg })
  vim.api.nvim_set_hl(0, "GtuiBarTitle", { fg = hl_attr("Title", "fg"), bg = bar_bg, bold = true })
  vim.api.nvim_set_hl(0, "GtuiBarDim", { fg = hl_attr("Comment", "fg"), bg = bar_bg })
  for env, src in pairs(ENV_SRC) do
    vim.api.nvim_set_hl(0, "GtuiEnv" .. env, { fg = normal_bg, bg = hl_attr(src, "fg"), bold = true })
  end
end
setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

local function esc(text)
  return (tostring(text):gsub("%%", "%%%%"))
end

local function bar_text(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local function var(name)
    local ok, v = pcall(vim.api.nvim_buf_get_var, buf, name)
    return ok and v or ""
  end
  local env = state.env()
  local parts = {
    "%#GtuiBarTitle# ▌ ", esc(var "gtui_title"), " ",
    "%#GtuiBar# ",
    ENV_SRC[env] and ("%#GtuiEnv" .. env .. "# ") or "%#GtuiBar# ", esc(env), " ",
    "%#GtuiBar#  ", esc(state.range:label()),
  }
  local info = var "gtui_info"
  if info ~= "" then
    parts[#parts + 1] = "%#GtuiBarDim#  · " .. esc(info)
  end
  parts[#parts + 1] = "%#GtuiBar#"
  return table.concat(parts)
end

local function update_bars()
  for win in pairs(bars) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winbar = bar_text(win)
    else
      bars[win] = nil
    end
  end
end

state.on_change(update_bars)

function M.set_info(buf, text)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_set_var(buf, "gtui_info", text .. "  updated " .. os.date "%H:%M:%S")
    update_bars()
  end
end

function M.scratch(title, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = ft or "gtui"
  vim.api.nvim_buf_set_var(buf, "gtui_title", title)
  return buf
end

function M.set_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

function M.use_bar(win)
  bars[win] = true
  update_bars()
end

-- range, env and refresh keys shared by every gtui results buffer
function M.common_maps(buf, refresh)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = "gtui: " .. desc })
  end
  local function act(fn)
    return function()
      fn()
      refresh()
    end
  end
  map("<localleader>r", refresh, "refresh")
  map("<localleader>e", act(state.cycle_env), "cycle environment")
  map("<localleader>]", act(function() state.cycle_preset(1) end), "next range preset")
  map("<localleader>[", act(function() state.cycle_preset(-1) end), "previous range preset")
  map("<localleader>u", act(state.undo_range), "undo range")
  map("<localleader>0", act(state.reset_range), "reset range")
  map("<localleader>y", function()
    vim.fn.setreg("+", state.range:to_json())
    vim.notify("yanked " .. state.range:to_json())
  end, "yank range")
  map("<localleader>p", function()
    local r, err = timerange.parse(vim.fn.getreg "+")
    if not r then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    state.set_range(r)
    refresh()
  end, "paste range")
  map("q", function()
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd.tabclose()
    end
  end, "close tab")
end

function M.ts_str(ns)
  return os.date("%m-%d %H:%M:%S", math.floor(tonumber(ns) / 1e9))
end

-- extmark highlights as { row, col, end_col, group }, rows relative to row0
function M.apply_hls(buf, ns, hls, row0)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(buf, ns, (row0 or 0) + h.row, h.col, { end_col = h.end_col, hl_group = h.group })
  end
end

-- new tab with a one-line prompt above a results buffer
function M.query_tab(opts)
  vim.cmd.tabnew()
  local t = { res_win = vim.api.nvim_get_current_win(), res_buf = M.scratch(opts.title) }
  vim.api.nvim_win_set_buf(t.res_win, t.res_buf)
  vim.cmd "1split"
  t.prompt_win = vim.api.nvim_get_current_win()
  t.prompt_buf = M.scratch(opts.title .. " query", "gtui")
  vim.api.nvim_win_set_buf(t.prompt_win, t.prompt_buf)
  vim.wo[t.prompt_win].winfixheight = true
  M.use_bar(t.res_win)
  M.set_lines(t.res_buf, { "" })
  vim.bo[t.prompt_buf].modifiable = true
  if opts.lang then pcall(vim.treesitter.start, t.prompt_buf, opts.lang) end
  if opts.ds then
    vim.b[t.prompt_buf].gtui_ds = opts.ds
    require("gtui.complete").prefetch(opts.ds)
  end

  local ns = vim.api.nvim_create_namespace "gtui_prompt"
  function t.query()
    return vim.trim(table.concat(vim.api.nvim_buf_get_lines(t.prompt_buf, 0, -1, false), " "))
  end
  local function placeholder()
    vim.api.nvim_buf_clear_namespace(t.prompt_buf, ns, 0, -1)
    if t.query() == "" then
      vim.api.nvim_buf_set_extmark(t.prompt_buf, ns, 0, 0, {
        virt_text = { { opts.placeholder, "Comment" } }, virt_text_pos = "overlay",
      })
    end
  end
  function t.set_query(text)
    vim.api.nvim_buf_set_lines(t.prompt_buf, 0, -1, false, { text })
    placeholder()
  end
  function t.focus_prompt()
    vim.api.nvim_set_current_win(t.prompt_win)
    vim.cmd "startinsert!"
  end
  for _, mode in ipairs { "n", "i" } do
    vim.keymap.set(mode, "<CR>", function()
      vim.cmd.stopinsert()
      opts.run()
    end, { buffer = t.prompt_buf, desc = "gtui: run query" })
  end
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { buffer = t.prompt_buf, callback = placeholder })
  placeholder()
  return t
end

return M
