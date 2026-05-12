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

return M
