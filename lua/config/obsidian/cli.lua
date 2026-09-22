--- Thin wrapper around the Obsidian desktop app's CLI (`obsidian ...`).
--- obsidian.nvim talks to the vault on disk; property writes, tasks and the
--- TaskNotes pomodoro go through the running app instead, so they stay in sync
--- with plugins that only the app knows about.
local M = {}

M.log_path = vim.fn.stdpath "cache" .. "/obsidian-vault.log"

--- Append-only debug log, mirroring what the old plugin wrote.
---@param body string
function M.log(body)
  local ts = vim.fn.strftime "%Y-%m-%d %H:%M:%S"
  local lines =
    vim.split("--- " .. ts .. " ---\n" .. (body or ""), "\n", { plain = true })
  pcall(vim.fn.writefile, lines, M.log_path, "a")
end

-- Homebrew's prefix differs per platform, so the executable is resolved rather
-- than hardcoded; none of this shells out.
local BREW_PREFIXES = {
  "/opt/homebrew",
  "/usr/local",
  "/home/linuxbrew/.linuxbrew",
  "~/.linuxbrew",
}

---@return string[]
local function brew_prefixes()
  local prefixes = {}
  local env_prefix = vim.env.HOMEBREW_PREFIX
  if env_prefix and env_prefix ~= "" then
    prefixes[#prefixes + 1] = env_prefix
  end
  local brew = vim.fn.exepath "brew"
  if brew ~= "" then
    prefixes[#prefixes + 1] = vim.fs.dirname(vim.fs.dirname(brew))
  end
  vim.list_extend(prefixes, BREW_PREFIXES)
  return prefixes
end

local resolved

--- Absolute path to the Obsidian CLI, looked up on `$PATH` and then under the
--- Homebrew prefix. Falls back to the bare name so failures name what was run.
---@return string
function M.executable()
  if resolved then
    return resolved
  end

  local path = vim.fn.exepath "obsidian"
  if path == "" then
    for _, prefix in ipairs(brew_prefixes()) do
      local candidate = vim.fn.expand(prefix) .. "/bin/obsidian"
      if vim.fn.executable(candidate) == 1 then
        path = candidate
        break
      end
    end
  end
  if path == "" then
    path = "obsidian"
    M.log "executable: obsidian not found on $PATH or a Homebrew prefix\n"
    vim.notify(
      "Could not find the Obsidian CLI ('obsidian').",
      vim.log.levels.ERROR
    )
  end

  resolved = path
  return path
end

--- Obsidian CLI expects `key="..."`. Escape `\` and `"` inside the value only.
---@param s string
---@return string
function M.escape(s)
  return (tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"'))
end

---@param s string
---@return string
local function normalize_output(s)
  s = vim.trim(s)
  if s:sub(1, 3) == "\239\187\191" then
    s = s:sub(4)
  end
  return s
end

--- Run a command and return its raw output.
---@param cmd string Arguments after the obsidian executable.
---@return string|nil
function M.run(cmd)
  local full = vim.fn.shellescape(M.executable()) .. " " .. cmd
  local output = vim.fn.system(full)
  if vim.v.shell_error ~= 0 then
    M.log("Encountered err: " .. output)
    vim.notify("Command failed: " .. full, vim.log.levels.ERROR)
    return nil
  end
  return output
end

--- Run a command and return trimmed text (stdout + stderr merged).
---@param cmd string Arguments after the obsidian executable.
---@return string|nil
function M.run_text(cmd)
  local full = vim.fn.shellescape(M.executable()) .. " " .. cmd .. " 2>&1"
  local output = vim.fn.system(full)
  if vim.v.shell_error ~= 0 then
    M.log("Encountered err: " .. output)
    vim.notify("Command failed: " .. full, vim.log.levels.ERROR)
    return nil
  end
  return normalize_output(output)
end

--- Run a command and parse JSON from stdout.
---@param cmd string Arguments after the obsidian executable.
---@return table|nil
function M.run_json(cmd)
  local full = vim.fn.shellescape(M.executable()) .. " " .. cmd
  local output = vim.fn.system(full)
  if vim.v.shell_error ~= 0 then
    M.log("No output found: " .. output)
    return nil
  end
  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok then
    M.log("Failed to parse JSON output: " .. tostring(result))
    return nil
  end
  return result
end

--- Run a command without blocking and parse JSON from stdout. Args are passed
--- to the executable directly, so values containing spaces need no quoting.
---@param args string[] Arguments after the obsidian executable.
---@param cb fun(result: table|nil, err: string|nil) Called on the main loop.
---@param silent? boolean Skip logging failures (for background polls).
function M.run_json_async(args, cb, silent)
  local cmd = { M.executable() }
  vim.list_extend(cmd, args)
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        local err = (res.stderr ~= "" and res.stderr) or res.stdout or "error"
        if not silent then
          M.log("Encountered err: " .. err)
        end
        cb(nil, err)
        return
      end
      local ok, result = pcall(vim.json.decode, res.stdout)
      if not ok or type(result) ~= "table" then
        local err = "could not parse output:\n" .. (res.stdout or "")
        if not silent then
          M.log(err)
        end
        cb(nil, err)
        return
      end
      cb(result, nil)
    end)
  end)
end

return M
