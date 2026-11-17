local M = {}

local config = {
  theme = "dark",
  background = "transparent",
  scale = 4,
  max_zoom = 8,
  size = 0.9,
  keymap = "<leader>mp",
}

local FENCE_OPEN = "^%s*([`~][`~][`~]+)%s*mermaid"

local function find_blocks(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local blocks, i = {}, 1
  while i <= #lines do
    local fence = lines[i]:match(FENCE_OPEN)
    if fence then
      local close = "^%s*" .. fence:sub(1, 1):rep(#fence) .. "+%s*$"
      local j = i + 1
      while j <= #lines and not lines[j]:match(close) do
        j = j + 1
      end
      blocks[#blocks + 1] = { first = i, last = j, lines = vim.list_slice(lines, i + 1, j - 1) }
      i = j
    end
    i = i + 1
  end
  return blocks
end

local function pick_block(cb)
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local blocks = find_blocks(buf)
  if #blocks == 0 then
    return vim.notify("No mermaid blocks in this buffer", vim.log.levels.WARN)
  end
  for _, b in ipairs(blocks) do
    if row >= b.first and row <= b.last then
      return cb(b)
    end
  end
  if #blocks == 1 then
    return cb(blocks[1])
  end
  vim.ui.select(blocks, {
    prompt = "Mermaid block",
    format_item = function(b)
      return ("line %d: %s"):format(b.first, vim.trim(b.lines[1] or ""))
    end,
  }, function(b)
    if b then
      cb(b)
    end
  end)
end

local V = {}
V.__index = V

function V:viewport()
  local sz = Snacks.image.terminal.size()
  local wpx = math.floor(self.cols * sz.cell_width)
  local hpx = math.floor(self.rows * sz.cell_height)
  local fit = math.min(wpx / self.iw, hpx / self.ih)
  return wpx, hpx, wpx / (fit * self.zoom), hpx / (fit * self.zoom)
end

function V:clamp()
  local _, _, rw, rh = self:viewport()
  local function axis(c, r, n)
    if r >= n then
      return n / 2
    end
    return math.max(r / 2, math.min(n - r / 2, c))
  end
  self.cx = axis(self.cx, rw, self.iw)
  self.cy = axis(self.cy, rh, self.ih)
end

function V:draw()
  if self.busy then
    self.dirty = true
    return
  end
  self.busy, self.dirty = true, false
  self:clamp()
  local wpx, hpx, rw, rh = self:viewport()
  local cw, ch = math.min(rw, self.iw), math.min(rh, self.ih)
  local x = math.max(0, math.min(self.iw - cw, self.cx - rw / 2))
  local y = math.max(0, math.min(self.ih - ch, self.cy - rh / 2))
  -- pad the axis that is smaller than the viewport so the aspect stays that of the window
  local ew, eh = math.floor(cw * wpx / rw + 0.5), math.floor(ch * hpx / rh + 0.5)
  self.n = self.n + 1
  local out = ("%s/view-%d.png"):format(self.dir, self.n)
  vim.system({
    "magick", self.src,
    "-crop", ("%dx%d+%d+%d"):format(math.floor(cw + 0.5), math.floor(ch + 0.5), math.floor(x + 0.5), math.floor(y + 0.5)),
    "+repage",
    "-resize", ("%dx%d!"):format(ew, eh),
    "-background", "none", "-gravity", "center", "-extent", ("%dx%d"):format(wpx, hpx),
    out,
  }, {}, vim.schedule_wrap(function(res)
    self.busy = false
    if self.closed then
      return
    end
    if res.code ~= 0 then
      return vim.notify("magick failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
    end
    local old = self.placement
    self.placement = Snacks.image.placement.new(self.buf, out, { pos = { 1, 0 } })
    if old then
      vim.defer_fn(function()
        old:close()
        os.remove(old.img.src)
      end, 60)
    end
    self:title()
    if self.dirty then
      self:draw()
    end
  end))
end

function V:title()
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_set_config(self.win, {
      title = (" mermaid  %d%%  hjkl pan  +/- zoom  0 fit  q close "):format(math.floor(self.zoom * 100 + 0.5)),
      title_pos = "center",
    })
  end
end

function V:close()
  if self.closed then
    return
  end
  self.closed = true
  if self.placement then
    self.placement:close()
  end
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  vim.fn.delete(self.dir, "rf")
end

function V:zoom_by(f)
  self.zoom = math.max(1, math.min(config.max_zoom, self.zoom * f))
  self:draw()
end

function V:pan(dx, dy)
  local _, _, rw, rh = self:viewport()
  self.cx = self.cx + dx * rw
  self.cy = self.cy + dy * rh
  self:draw()
end

function V:reset()
  self.zoom, self.cx, self.cy = 1, self.iw / 2, self.ih / 2
  self:draw()
end

local function open_view(png)
  local info = vim.system({ "magick", "identify", "-format", "%w %h", png }, { text = true }):wait()
  local iw, ih = info.stdout:match("(%d+) (%d+)")
  if not iw then
    return vim.notify("Could not read rendered image", vim.log.levels.ERROR)
  end

  local cols = math.floor(vim.o.columns * config.size)
  local rows = math.floor((vim.o.lines - vim.o.cmdheight) * config.size)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = cols,
    height = rows,
    col = math.floor((vim.o.columns - cols) / 2),
    row = math.floor((vim.o.lines - rows) / 2) - 1,
    style = "minimal",
    border = "rounded",
  })

  local v = setmetatable({
    buf = buf, win = win, src = png, dir = vim.fs.dirname(png),
    iw = tonumber(iw), ih = tonumber(ih), cols = cols, rows = rows,
    zoom = 1, cx = tonumber(iw) / 2, cy = tonumber(ih) / 2, n = 0,
  }, V)

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  local function count()
    return math.max(1, vim.v.count)
  end
  for lhs, d in pairs { h = { -1, 0 }, l = { 1, 0 }, k = { 0, -1 }, j = { 0, 1 } } do
    map(lhs, function() v:pan(d[1] * 0.1 * count(), d[2] * 0.1 * count()) end)
    map(lhs:upper(), function() v:pan(d[1] * 0.5 * count(), d[2] * 0.5 * count()) end)
  end
  map("<C-d>", function() v:pan(0, 0.5) end)
  map("<C-u>", function() v:pan(0, -0.5) end)
  map("+", function() v:zoom_by(1.25 ^ count()) end)
  map("=", function() v:zoom_by(1.25 ^ count()) end)
  map("-", function() v:zoom_by(1.25 ^ -count()) end)
  map("0", function() v:reset() end)
  map("q", function() v:close() end)
  map("<Esc>", function() v:close() end)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function() v:close() end,
  })
  v:draw()
end

function M.open()
  if vim.fn.executable "mmdc" == 0 or vim.fn.executable "magick" == 0 then
    return vim.notify("mermaid_pop needs mmdc and magick on PATH", vim.log.levels.ERROR)
  end
  if not Snacks.image.supports_terminal() then
    return vim.notify("Terminal does not support the kitty graphics protocol", vim.log.levels.ERROR)
  end
  pick_block(function(block)
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    local mmd, png = dir .. "/chart.mmd", dir .. "/chart.png"
    vim.fn.writefile(block.lines, mmd)
    local msg = " Rendering mermaid... "
    local nbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(nbuf, 0, -1, false, { msg })
    local nwin = vim.api.nvim_open_win(nbuf, false, {
      relative = "editor",
      width = #msg,
      height = 1,
      col = math.floor((vim.o.columns - #msg) / 2),
      row = math.floor(vim.o.lines / 2),
      style = "minimal",
      border = "rounded",
      focusable = false,
      noautocmd = true,
    })
    vim.system({
      "mmdc", "-q", "-i", mmd, "-o", png,
      "-s", tostring(config.scale), "-t", config.theme, "-b", config.background,
    }, { text = true }, vim.schedule_wrap(function(res)
      if vim.api.nvim_win_is_valid(nwin) then
        vim.api.nvim_win_close(nwin, true)
      end
      if vim.api.nvim_buf_is_valid(nbuf) then
        vim.api.nvim_buf_delete(nbuf, { force = true })
      end
      if res.code ~= 0 then
        vim.fn.delete(dir, "rf")
        return vim.notify("mmdc failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
      end
      open_view(png)
    end))
  end)
end

function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})
  vim.api.nvim_create_user_command("MermaidPop", M.open, {})
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "mermaid" },
    callback = function(e)
      vim.keymap.set("n", config.keymap, M.open, { buffer = e.buf, desc = "Mermaid popout" })
    end,
  })
end

return M
