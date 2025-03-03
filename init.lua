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

vim.opt.wrap = false
vim.opt.cmdheight = 0
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.bo.softtabstop = 2
vim.opt.fillchars:append { eob = " " }
vim.opt.termguicolors = true
vim.opt.textwidth = 80

-- Set statuscolumn with highlight groups
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.statuscolumn = "%#SignColumn#%s %#LineNumber#%l %#RelativeNumber#%r "

vim.api.nvim_set_option_value("clipboard", "unnamed", {})
vim.diagnostic.config { virtual_text = false }

-- NVIM Tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

-- Render whitespaces
vim.opt.listchars = {
  space = "·",
  tab = "->",
}

-- Enable list mode to show the characters
vim.opt.list = true

-- Adjust padding on enter and load
vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  callback = function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    if not normal.bg then
      return
    end
    io.write(string.format("\027]11;#%06x\027\\", normal.bg))
  end,
})

vim.api.nvim_create_autocmd("UILeave", {
  callback = function()
    io.write "\027]111\027\\"
  end,
})

vim.schedule(function()
  require "mappings"
end)
