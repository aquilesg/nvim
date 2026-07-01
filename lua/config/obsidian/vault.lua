local M = {}

M.brain_loc = "~/Repos/brain/"

M.is_in_brain = function(buf_id)
  local buf_path = vim.api.nvim_buf_get_name(buf_id)
  local brain_path = vim.fn.expand(M.brain_loc)
  return string.sub(buf_path, 1, string.len(brain_path)) == brain_path
end

return M
