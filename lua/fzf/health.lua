local health = vim.health

local M = {}

function M.check()
  health.start("fzf")

  if vim.fn.executable("fzf") == 1 then
    health.ok("fzf installed")
  else
    health.error("fzf missing")
  end

  if vim.fn.executable("rg") == 1 then
    health.ok("ripgrep installed")
  else
    health.error("ripgrep missing")
  end
end

return M
