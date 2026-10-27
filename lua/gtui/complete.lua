local http = require "gtui.http"
local config = require "gtui.config"
local state = require "gtui.state"

local M = {}

local PROM_FUNCS = {
  "rate", "irate", "increase", "delta", "idelta", "deriv", "sum", "avg", "min", "max", "count", "stddev",
  "topk", "bottomk", "quantile", "histogram_quantile", "sum_over_time", "avg_over_time", "max_over_time",
  "min_over_time", "count_over_time", "quantile_over_time", "absent", "absent_over_time", "label_replace",
  "label_join", "clamp_min", "clamp_max", "round", "ceil", "floor", "abs", "sort", "sort_desc", "time",
  "vector", "scalar", "by", "without", "on", "ignoring", "group_left", "group_right", "offset", "bool",
}
local LOKI_FUNCS = {
  "rate", "count_over_time", "bytes_rate", "bytes_over_time", "absent_over_time", "sum", "avg", "min", "max",
  "count", "topk", "bottomk", "quantile_over_time", "by", "without", "json", "logfmt", "pattern", "regexp",
  "unpack", "line_format", "label_format", "unwrap", "drop", "keep", "decolorize",
}

local cache = {}

local function window()
  local now = os.time()
  return now - 3600, now
end

local function base(ds)
  return ds == "loki" and (config.loki .. "/loki/api/v1") or (config.mimir .. "/api/v1")
end

-- cached async list; cb(items) fires once fetched. match is a series selector (promql) or stream selector (loki)
local function fetch(ds, path, match, cb)
  local env = state.env()
  local scope = ('{tng_environment="%s"}'):format(env)
  local key = table.concat({ ds, env, path, match or "" }, "|")
  local hit = cache[key]
  if hit then
    if hit.items then
      return cb(hit.items)
    end
    table.insert(hit.waiting, cb)
    return
  end
  local entry = { waiting = { cb } }
  cache[key] = entry
  local s, e = window()
  local params = { { "start", ds == "loki" and (s .. "000000000") or s }, { "end", ds == "loki" and (e .. "000000000") or e } }
  if ds == "loki" then
    table.insert(params, { "query", match or scope })
  else
    table.insert(params, { "match[]", match or scope })
  end
  http.get(base(ds) .. path, params, nil, function(err, d)
    if err or not d.data then
      cache[key] = nil
      d = { data = {} }
    end
    entry.items = d.data
    for _, w in ipairs(entry.waiting) do
      w(entry.items)
    end
  end)
end

function M.prefetch(ds)
  if ds == "mimir" then
    fetch(ds, "/label/__name__/values", nil, function() end)
  end
end

local function items_of(names, kind, detail)
  local out = {}
  for _, n in ipairs(names) do
    out[#out + 1] = { label = n, kind = kind, labelDetails = detail and { description = detail } or nil }
  end
  return out
end

local function static(list)
  return items_of(list, require("blink.cmp.types").CompletionItemKind.Function)
end

local Kind = function()
  return require("blink.cmp.types").CompletionItemKind
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return vim.bo.filetype == "gtui" and vim.b.gtui_ds ~= nil
end

function M:get_trigger_characters()
  return { "{", ",", '"' }
end

function M:get_completions(ctx, callback)
  local ds = vim.b[ctx.bufnr].gtui_ds
  local before = ctx.line:sub(1, ctx.cursor[2])
  local function done(items)
    callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
  end

  local open = before:match "^.*(){"
  local close = before:match "^.*()}"
  if open and (not close or close < open) then
    local inside = before:sub(open + 1)
    local label = inside:match '([%a_][%w_]*)%s*[=!~]+%s*"[^"]*$'
    local selector
    if ds == "mimir" then
      local metric = before:sub(1, open - 1):match "([%a_:][%w_:]*)%s*$"
      if metric then
        selector = ('%s{tng_environment="%s"}'):format(metric, state.env())
      end
    end
    if label then
      return fetch(ds, "/label/" .. label .. "/values", selector, function(vals)
        done(items_of(vals, Kind().Value))
      end)
    end
    return fetch(ds, "/labels", selector, function(names)
      done(items_of(names, Kind().Field))
    end)
  end

  local funcs = static(ds == "loki" and LOKI_FUNCS or PROM_FUNCS)
  if ds == "loki" then
    return done(funcs)
  end
  fetch(ds, "/label/__name__/values", nil, function(names)
    local items = items_of(names, Kind().Variable)
    vim.list_extend(items, funcs)
    done(items)
  end)
end

return M
