local config = require "gtui.config"
local timerange = require "gtui.timerange"

local M = {
  env_i = 1,
  range_i = config.default_range,
  stack = {},
  listeners = {},
}
M.range = timerange.new("now-" .. config.ranges[M.range_i][1])

local function changed()
  for _, fn in ipairs(M.listeners) do
    pcall(fn)
  end
end

function M.on_change(fn)
  table.insert(M.listeners, fn)
end

function M.env()
  return config.envs[M.env_i]
end

function M.window()
  return M.range:resolve()
end

function M.seconds()
  local s, e = M.window()
  return math.floor(e - s)
end

function M.vars(extra)
  local v = vim.deepcopy(extra or {})
  for _, name in ipairs(config.env_vars) do
    v[name] = M.env()
  end
  return v
end

function M.set_range(r, push)
  if push ~= false then
    table.insert(M.stack, M.range)
  end
  M.range = r
  changed()
end

local function preset_range()
  return timerange.new("now-" .. config.ranges[M.range_i][1])
end

function M.cycle_preset(delta)
  M.range_i = (M.range_i - 1 + delta) % #config.ranges + 1
  M.set_range(preset_range())
end

function M.reset_range()
  M.set_range(preset_range())
end

function M.undo_range()
  local r = table.remove(M.stack)
  if r then
    M.set_range(r, false)
  end
end

function M.cycle_env()
  M.env_i = M.env_i % #config.envs + 1
  changed()
end

function M.step_for(seconds)
  return math.max(15, math.floor(seconds / 200))
end

-- expands $environment, ${x}, ${x:fmt}, [[x]] and Grafana builtins
-- keep_env leaves the environment variables and Grafana builtins for the destination to expand
function M.subst(expr, extra, keep_env)
  local values
  if keep_env then
    values = vim.deepcopy(extra or {})
  else
    local secs = M.seconds()
    values = vim.tbl_extend("force", {
      __rate_interval = "5m",
      __interval = M.step_for(secs) .. "s",
      __range = secs .. "s",
    }, M.vars(extra))
  end
  local function rep(name)
    return values[name]
  end
  expr = expr:gsub("%${([%w_]+):[%w_]+}", rep)
  expr = expr:gsub("%${([%w_]+)}", rep)
  expr = expr:gsub("%[%[([%w_]+)%]%]", rep)
  expr = expr:gsub("%$([%w_]+)", rep)
  return expr
end

return M
