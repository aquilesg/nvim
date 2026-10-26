local M = {}

local TABS = { logs = "<leader>Gl", metrics = "<leader>Gm", dashboards = "<leader>Gd" }

function M.setup()
  vim.api.nvim_create_user_command("Gtui", function(o)
    require("gtui." .. (o.args ~= "" and o.args or "logs")).open()
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(TABS)
    end,
  })
  for name, lhs in pairs(TABS) do
    vim.keymap.set("n", lhs, function()
      require("gtui." .. name).open()
    end, { desc = "gtui " .. name })
  end
end

return M
