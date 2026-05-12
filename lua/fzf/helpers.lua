local M = {}

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

function M.jump(filepath, line, col)
  vim.cmd("hide edit " .. vim.fn.fnameescape(filepath))

  local l = tonumber(line) or 1
  local c = tonumber(col) or 1

  pcall(vim.api.nvim_win_set_cursor, 0, { l, c - 1 })

  vim.cmd("normal! zz")
end

function M.build_fzf_opts(opts)
  local parts = {}

  for key, value in pairs(opts or {}) do
    if value == "" then
      table.insert(parts, key)
    else
      table.insert(parts, key .. "=" .. value)
    end
  end

  return table.concat(parts, " ")
end

function M.join_path(root, file)
  root = root:gsub("/$", "")
  file = file:gsub("^/", "")

  return root .. "/" .. file
end

return M
