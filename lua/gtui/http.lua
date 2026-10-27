local config = require "gtui.config"

local M = {}

local function fmt_ns(x)
  return type(x) == "string" and x or string.format("%.0f", x)
end

-- cb(err, decoded_json); runs on the main loop
function M.get(url, params, headers, cb)
  local cmd = { "curl", "-sS", "--max-time", "30", "-G", url, "-w", "\n%{http_code}" }
  for _, kv in ipairs(params or {}) do
    vim.list_extend(cmd, { "--data-urlencode", kv[1] .. "=" .. tostring(kv[2]) })
  end
  if vim.startswith(url, config.loki) then
    vim.list_extend(cmd, { "-H", "X-Scope-OrgID: " .. config.loki_tenant })
  end
  for _, h in ipairs(headers or {}) do
    vim.list_extend(cmd, { "-H", h })
  end
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(res)
    if res.code ~= 0 then
      local msg = vim.trim(res.stderr or "")
      return cb(msg ~= "" and msg or ("curl exit " .. res.code))
    end
    local body, status = res.stdout:match "^(.*)\n(%d+)$"
    if not body then
      return cb "unparseable curl output"
    end
    if tonumber(status) >= 400 then
      return cb(("HTTP %s: %s"):format(status, body:sub(1, 300)))
    end
    local ok, data = pcall(vim.json.decode, body, { luanil = { object = true, array = true } })
    if not ok then
      return cb("bad JSON: " .. body:sub(1, 100))
    end
    cb(nil, data)
  end))
end

-- rows ascending by time: { ts = "<ns string>", stream = {..}, line = "..." }
function M.loki_logs(query, start_ns, end_ns, limit, cb)
  M.get(config.loki .. "/loki/api/v1/query_range", {
    { "query", query }, { "start", fmt_ns(start_ns) }, { "end", fmt_ns(end_ns) },
    { "limit", limit or 500 }, { "direction", "backward" },
  }, nil, function(err, d)
    if err then
      return cb(err)
    end
    local rows = {}
    for _, s in ipairs(d.data.result) do
      for _, v in ipairs(s.values) do
        rows[#rows + 1] = { ts = v[1], stream = s.stream, line = v[2] }
      end
    end
    table.sort(rows, function(a, b)
      if #a.ts ~= #b.ts then
        return #a.ts < #b.ts
      end
      return a.ts < b.ts
    end)
    cb(nil, rows)
  end)
end

local function prom_base(ds)
  return ds == "loki" and (config.loki .. "/loki/api/v1") or (config.mimir .. "/api/v1")
end

local function series_name(metric)
  local keys = {}
  for k in pairs(metric) do
    if k ~= "__name__" then
      keys[#keys + 1] = k
    end
  end
  table.sort(keys)
  local rest = {}
  for _, k in ipairs(keys) do
    rest[#rest + 1] = k .. "=" .. metric[k]
  end
  local name = metric.__name__ or ""
  if #rest > 0 then
    return name .. "{" .. table.concat(rest, ",") .. "}"
  end
  return name ~= "" and name or "value"
end

-- cb(err, { { name = "...", points = { { t, v }, ... } }, ... })
function M.series(ds, expr, start, stop, cb)
  local step = math.max(15, math.floor((stop - start) / 200))
  local from, to = string.format("%.3f", start), string.format("%.3f", stop)
  if ds == "loki" then
    from, to = fmt_ns(start * 1e9), fmt_ns(stop * 1e9)
  end
  M.get(prom_base(ds) .. "/query_range", {
    { "query", expr }, { "start", from }, { "end", to }, { "step", step },
  }, nil, function(err, d)
    if err then
      return cb(err)
    end
    local out = {}
    for _, r in ipairs(d.data.result) do
      local pts = {}
      for _, v in ipairs(r.values) do
        pts[#pts + 1] = { tonumber(v[1]), tonumber(v[2]) }
      end
      out[#out + 1] = { name = series_name(r.metric), metric = r.metric, points = pts }
    end
    cb(nil, out)
  end)
end

-- cb(err, { { metric = {..}, value = number }, ... })
function M.instant(ds, expr, at, cb)
  M.get(prom_base(ds) .. "/query", {
    { "query", expr }, { "time", ds == "loki" and fmt_ns(at * 1e9) or string.format("%.3f", at) },
  }, nil, function(err, d)
    if err then
      return cb(err)
    end
    local out = {}
    for _, r in ipairs(d.data.result) do
      out[#out + 1] = { metric = r.metric, value = tonumber(r.value[2]) }
    end
    cb(nil, out)
  end)
end

function M.grafana(path, params, cb)
  M.get(config.grafana .. path, params, { "Authorization: Bearer " .. tostring(config.grafana_token) }, cb)
end

return M
