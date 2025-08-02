if vim.env.PROF then
  local snacks = vim.fn.stdpath "data" .. "/lazy/snacks.nvim"
  vim.opt.rtp:append(snacks)
  require("snacks.profiler").startup {
    startup = {
      event = "VimEnter",
    },
  }
end

require "config.lazy"

-- Editor options (grouped for clarity)
vim.opt.wrap = false
vim.opt.cmdheight = 0
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.fillchars:append { eob = " " }
vim.opt.termguicolors = true
vim.opt.listchars = { space = "·", tab = "->" }
vim.opt.list = true

-- Window options
vim.wo.number = true

-- Clipboard (set globally)
vim.opt.clipboard = "unnamed"

-- Diagnostics
vim.diagnostic.config {
  virtual_lines = true,
}

-- Disable netrw (for nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Folding method (use autocmd group for easier management)
local fold_group = vim.api.nvim_create_augroup("FoldManual", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = fold_group,
  pattern = "*",
  callback = function()
    vim.opt.foldmethod = "manual"
  end,
})

-- Adjust padding on enter and load (use autocmd group)
local ui_group = vim.api.nvim_create_augroup("UIPadding", { clear = true })
vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  group = ui_group,
  callback = function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    if normal.bg then
      io.write(string.format("\027]11;#%06x\027\\", normal.bg))
    end
  end,
})
vim.api.nvim_create_autocmd("UILeave", {
  group = ui_group,
  callback = function()
    io.write "\027]111\027\\"
  end,
})
