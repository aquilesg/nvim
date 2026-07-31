-- Cached macOS Wi-Fi status for the statusline.
-- Polls `ipconfig getsummary <iface>` on a timer instead of shelling out on
-- every statusline refresh, mirroring how battery.nvim caches its result.
local M = {}

local WIFI_IF = "en0"

M.cache = { icon = "󰖪", ssid = "" }

local function poll()
  vim.system(
    { "ipconfig", "getsummary", WIFI_IF },
    { text = true },
    function(res)
      local ssid
      if res.code == 0 and res.stdout then
        for line in res.stdout:gmatch "[^\r\n]+" do
          local s = line:match "^%s*SSID%s*:%s*(.+)$"
          if s then
            ssid = (s:gsub("%s+$", ""))
            break
          end
        end
      end
      if ssid and ssid ~= "" then
        M.cache = { icon = "󰖩", ssid = ssid }
      else
        M.cache = { icon = "󰖪", ssid = "" }
      end
    end
  )
end

function M.setup(opts)
  opts = opts or {}
  local interval = (opts.update_rate_seconds or 30) * 1000
  poll()
  local timer = vim.uv.new_timer()
  timer:start(interval, interval, vim.schedule_wrap(poll))
end

function M.statusline()
  return M.cache.icon
end

return M
