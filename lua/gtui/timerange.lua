local M = {}

local UNITS = { s = 1, m = 60, h = 3600, d = 86400, w = 604800, M = 2592000, y = 31536000 }

local function days_from_civil(y, m, d)
  if m <= 2 then
    y = y - 1
  end
  local era = math.floor(y / 400)
  local yoe = y - era * 400
  local doy = math.floor((153 * (m + (m > 2 and -3 or 9)) + 2) / 5) + d - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

local function iso(s)
  local y, mo, d, h, mi, sec, frac, tz =
    s:match "^(%d+)-(%d+)-(%d+)[T ](%d+):(%d+):?(%d*)%.?(%d*)(.*)$"
  if not y then
    y, mo, d = s:match "^(%d+)-(%d+)-(%d+)$"
    h, mi, sec, frac, tz = 0, 0, 0, "", ""
  end
  if not y then
    error("bad time: " .. s)
  end
  y, mo, d, h, mi, sec = tonumber(y), tonumber(mo), tonumber(d), tonumber(h), tonumber(mi), tonumber(sec) or 0
  local t
  if tz == "" then
    t = os.time { year = y, month = mo, day = d, hour = h, min = mi, sec = sec }
  else
    local offset = 0
    if tz ~= "Z" then
      local sign, oh, om = tz:match "^([+-])(%d%d):?(%d%d)$"
      if not sign then
        error("bad time zone: " .. tz)
      end
      offset = (tonumber(oh) * 3600 + tonumber(om) * 60) * (sign == "-" and -1 or 1)
    end
    t = days_from_civil(y, mo, d) * 86400 + h * 3600 + mi * 60 + sec - offset
  end
  return t + (frac ~= "" and tonumber("0." .. frac) or 0)
end

local function resolve(s, now)
  s = vim.trim(s)
  if s == "now" then
    return now
  end
  local sign, n, unit = s:match "^now([+-])(%d+)([smhdwMy])$"
  if sign then
    local delta = tonumber(n) * UNITS[unit]
    return sign == "-" and now - delta or now + delta
  end
  if s:match "^%d+$" then
    return tonumber(s) / 1000
  end
  return iso(s)
end

local R = {}
R.__index = R

function M.new(from, to)
  return setmetatable({ from = from, to = to or "now" }, R)
end

function R:resolve(now)
  now = now or os.time()
  return resolve(self.from, now), resolve(self.to, now)
end

function R:relative()
  return self.to == "now" and vim.startswith(self.from, "now-")
end

function R:label()
  if self:relative() then
    return self.from:sub(5)
  end
  local s, e = self:resolve()
  return os.date("%m-%d %H:%M", math.floor(s)) .. " -> " .. os.date("%m-%d %H:%M", math.floor(e))
end

function R:to_json()
  return ('{"from":%s,"to":%s}'):format(vim.json.encode(self.from), vim.json.encode(self.to))
end

-- returns range, or nil and an error message
function M.parse(text)
  text = vim.trim(text)
  local from, to
  local ok, d = pcall(vim.json.decode, text)
  if ok and type(d) == "table" and d.from and d.to then
    from, to = tostring(d.from), tostring(d.to)
  else
    local q = text:match "%?(.*)$" or text
    from, to = q:match "from=([^&]+)", q:match "to=([^&]+)"
    if from and to then
      from, to = vim.uri_decode(from), vim.uri_decode(to)
    end
  end
  local bad = ("not a time range: %q"):format(text:sub(1, 60))
  if not (from and to) then
    return nil, bad
  end
  local r = M.new(from, to)
  local rok, s, e = pcall(r.resolve, r)
  if not rok then
    return nil, bad
  end
  if s >= e then
    return nil, "range start is not before end"
  end
  return r
end

return M
