local M = {}

local PALETTE = {
  "#61afef", "#e5c07b", "#98c379", "#e06c75", "#c678dd", "#56b6c2",
  "#d19a66", "#be5046", "#7f848e", "#e6e6e6", "#4db5bd", "#ff9e64",
}
local BITS = { [0] = { [0] = 0x01, 0x02, 0x04, 0x40 }, [1] = { [0] = 0x08, 0x10, 0x20, 0x80 } }
local GUTTER = 9
local FRAME, GRID, DIM = "FloatBorder", "NonText", "Comment"

local function setup_hl()
  for i, c in ipairs(PALETTE) do
    vim.api.nvim_set_hl(0, "GtuiSeries" .. i, { fg = c, default = true })
  end
end
setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

M.gutter = GUTTER + 1 -- display columns left of the plot area

function M.group(i)
  return "GtuiSeries" .. ((i - 1) % #PALETTE + 1)
end

local cells = {}
local function braille(b)
  cells[b] = cells[b] or vim.fn.nr2char(0x2800 + b, true)
  return cells[b]
end

local function human(v)
  local a = math.abs(v)
  for _, u in ipairs { { 1e12, "T" }, { 1e9, "G" }, { 1e6, "M" }, { 1e3, "k" } } do
    if a >= u[1] then
      return ("%.3g%s"):format(v / u[1], u[2])
    end
  end
  return ("%.4g"):format(v)
end

local function valid(v)
  return v == v and math.abs(v) ~= math.huge
end

local function bresenham(plot, x0, y0, x1, y1)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    plot(x0, y0)
    if x0 == x1 and y0 == y1 then
      break
    end
    local e2 = 2 * err
    if e2 >= dy then
      err = err + dy
      x0 = x0 + sx
    end
    if e2 <= dx then
      err = err + dx
      y0 = y0 + sy
    end
  end
end

-- series: { { name, points = { {t, v}, ... } } }
-- opts: width, height (cells of the plot area), marks = { { frac, group } }, legend_max
-- framed (default) adds 3 lines (top, bottom, x labels) and a border column on each side of the plot;
-- opts.frame = false drops the box and keeps only the y axis and the bottom axis (2 lines)
-- returns { lines, hls = { {row, col, end_col, group} }, t0, t1, width }
function M.render(series, opts)
  local W, H = opts.width, opts.height
  local framed = opts.frame ~= false
  local off = framed and 1 or 0
  local t0, t1, ymin, ymax = math.huge, -math.huge, math.huge, -math.huge
  for _, s in ipairs(series) do
    for _, p in ipairs(s.points) do
      if valid(p[2]) then
        t0, t1 = math.min(t0, p[1]), math.max(t1, p[1])
        ymin, ymax = math.min(ymin, p[2]), math.max(ymax, p[2])
      end
    end
  end
  if t0 == math.huge then
    return { lines = { "no data" }, hls = {}, width = W }
  end
  if t1 == t0 then
    t1 = t0 + 1
  end
  if ymax == ymin then
    local d = ymin == 0 and 1 or math.abs(ymin) * 0.1
    ymin, ymax = ymin - d, ymax + d
  end

  local DW, DH = W * 2, H * 4
  local bits, owner = {}, {}
  for r = 1, H do
    bits[r], owner[r] = {}, {}
    for c = 1, W do
      bits[r][c] = 0
    end
  end
  for si, s in ipairs(series) do
    local function plot(x, y)
      if x < 0 or y < 0 or x >= DW or y >= DH then
        return
      end
      local r, c = math.floor(y / 4) + 1, math.floor(x / 2) + 1
      bits[r][c] = bit.bor(bits[r][c], BITS[x % 2][y % 4])
      owner[r][c] = si
    end
    local prev
    for _, p in ipairs(s.points) do
      if valid(p[2]) then
        local x = math.floor((p[1] - t0) / (t1 - t0) * (DW - 1) + 0.5)
        local y = math.floor((1 - (p[2] - ymin) / (ymax - ymin)) * (DH - 1) + 0.5)
        if prev then
          bresenham(plot, prev[1], prev[2], x, y)
        else
          plot(x, y)
        end
        prev = { x, y }
      end
    end
  end

  local mark_cols = {}
  for _, m in ipairs(opts.marks or {}) do
    local c = math.max(1, math.min(W, math.floor(m[1] * (W - 1) + 0.5) + 1))
    mark_cols[c] = m[2]
  end

  local pad = string.rep(" ", GUTTER)
  local lines, hls = {}, {}
  local function hl(row, col, end_col, group)
    hls[#hls + 1] = { row = row, col = col, end_col = end_col, group = group }
  end

  if framed then
    local top = pad .. "╭" .. string.rep("─", W) .. "╮"
    lines[1] = top
    hl(0, GUTTER, #top, FRAME)
  end

  local mid = math.ceil(H / 2)
  local labels = { [1] = ymax, [mid] = (ymin + ymax) / 2, [H] = ymin }
  for r = 1, H do
    local left
    if labels[r] then
      left = ("%" .. GUTTER .. "s"):format(human(labels[r])) .. "┤"
      hl(r - 1 + off, 0, GUTTER, DIM)
    else
      left = pad .. "│"
    end
    hl(r - 1 + off, GUTTER, #left, FRAME)
    local parts, col = { left }, #left
    for c = 1, W do
      local ch, group
      if bits[r][c] ~= 0 then
        ch, group = braille(bits[r][c]), M.group(owner[r][c])
      elseif mark_cols[c] then
        ch, group = "│", mark_cols[c]
      elseif r == 1 or r == mid then
        ch, group = "·", GRID
      else
        ch = " "
      end
      if group then
        hl(r - 1 + off, col, col + #ch, group)
      end
      parts[#parts + 1] = ch
      col = col + #ch
    end
    if framed then
      parts[#parts + 1] = "│"
      hl(r - 1 + off, col, col + #"│", FRAME)
    end
    lines[#lines + 1] = table.concat(parts)
  end

  local n = math.max(2, math.min(5, math.floor(W / 14) + 1))
  local tick = {}
  for i = 0, n - 1 do
    tick[1 + math.floor(i * (W - 1) / (n - 1) + 0.5)] = i
  end
  local bottom = { pad, framed and "╰" or "└" }
  for c = 1, W do
    bottom[#bottom + 1] = tick[c] and "┬" or "─"
  end
  if framed then
    bottom[#bottom + 1] = "╯"
  end
  lines[#lines + 1] = table.concat(bottom)
  hl(H + off, GUTTER, #lines[#lines], FRAME)

  local tf = (t1 - t0) > 86400 and "%m-%d %H:%M" or "%H:%M:%S"
  local axis = string.rep(" ", GUTTER + 1 + W + 1)
  for c, i in pairs(tick) do
    local label = os.date(tf, math.floor(t0 + i / (n - 1) * (t1 - t0)))
    local start = c - math.floor(#label / 2)
    if i == 0 then
      start = c
    elseif i == n - 1 then
      start = c - #label + 1
    end
    start = GUTTER + 1 + math.max(1, math.min(W - #label + 1, start))
    axis = axis:sub(1, start - 1) .. label .. axis:sub(start + #label)
  end
  lines[#lines + 1] = axis
  hl(H + off + 1, 0, #axis, DIM)

  local shown = math.min(#series, opts.legend_max or #series, #PALETTE)
  for i = 1, shown do
    local lo, hi, last = math.huge, -math.huge, nil
    for _, p in ipairs(series[i].points) do
      if valid(p[2]) then
        lo, hi, last = math.min(lo, p[2]), math.max(hi, p[2]), p[2]
      end
    end
    local stats = last and ("last %s  min %s  max %s"):format(human(last), human(lo), human(hi)) or "no data"
    local name_w = math.max(10, W - #stats - 4)
    local name = series[i].name
    if vim.fn.strdisplaywidth(name) > name_w then
      name = vim.fn.strcharpart(name, 0, name_w - 1) .. "…"
    end
    local head = string.rep(" ", GUTTER + 1) .. "■ " .. name
    local line = head .. string.rep(" ", name_w - vim.fn.strdisplaywidth(name)) .. "  " .. stats
    lines[#lines + 1] = line
    hl(#lines - 1, GUTTER + 1, GUTTER + 1 + #"■", M.group(i))
    hl(#lines - 1, #line - #stats, #line, DIM)
  end
  if #series > shown then
    lines[#lines + 1] = string.rep(" ", GUTTER + 1) .. ("... %d more series"):format(#series - shown)
    hl(#lines - 1, 0, #lines[#lines], DIM)
  end
  return { lines = lines, hls = hls, t0 = t0, t1 = t1, width = W }
end

return M
