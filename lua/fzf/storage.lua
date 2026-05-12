local M = {}

M.sessions_dir =
    vim.fn.expand("~/.local/share/nvim/sessions")

vim.fn.mkdir(M.sessions_dir, "p")

local harpoon_file =
    vim.fn.stdpath("data") .. "/harpoon.json"

function M.harpoon_load()
  local f = io.open(harpoon_file, "r")

  if not f then
    return {}
  end

  local content = f:read("*all")

  f:close()

  local ok, data =
      pcall(vim.fn.json_decode, content)

  return (ok and data) or {}
end

function M.harpoon_save(data)
  local f = io.open(harpoon_file, "w")

  if f then
    f:write(vim.fn.json_encode(data))
    f:close()
  end
end

local git_root_cache = {}

function M.get_git_root()
  local cwd = vim.fn.getcwd()

  if git_root_cache[cwd] then
    return git_root_cache[cwd]
  end

  local root_result =
      vim.fn.systemlist(
        "git rev-parse --show-toplevel 2>/dev/null"
      )

  local root

  if vim.v.shell_error == 0
      and root_result[1]
      and not root_result[1]:match("^fatal")
  then
    root = root_result[1]
  else
    root = cwd
  end

  git_root_cache[cwd] = root

  return root
end

return M
