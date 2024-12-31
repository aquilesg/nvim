if vim.env.PROF then
  -- example for lazy.nvim
  -- change this to the correct path for your plugin manager
  local snacks = vim.fn.stdpath "data" .. "/lazy/snacks.nvim"
  vim.opt.rtp:append(snacks)
  require("snacks.profiler").startup {
    startup = {
      event = "VimEnter", -- stop profiler on this event. Defaults to `VimEnter`
      -- event = "UIEnter",
      -- event = "VeryLazy",
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

-- Status column stuff
vim.api.nvim_set_hl(0, "StatusColumnSign", { fg = "#FFB3BA" })
vim.api.nvim_set_hl(0, "StatusColumnLineNr", { fg = "#BAFFC9" })
vim.api.nvim_set_hl(0, "StatusColumnRelative", { fg = "#BAE1FF" })

-- Set statuscolumn with highlight groups
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.statuscolumn = "%#SignColumn#%s %#LineNumber#%l %#RelativeNumber#%r "

vim.api.nvim_set_option("clipboard", "unnamed")
vim.diagnostic.config {
  virtual_text = false,
}

-- NVIM Tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

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
