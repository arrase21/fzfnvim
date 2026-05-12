local health = vim.health

local M = {}

function M.check()
  health.start("fzf")

  if vim.fn.executable("fzf") == 1 then
    health.ok("fzf installed")
  else
    health.error("fzf missing — required for picker")
  end

  if vim.fn.executable("rg") == 1 then
    health.ok("ripgrep installed")
  else
    health.warn("ripgrep missing — needed for grep/files search")
  end

  if vim.fn.executable("bat") == 1 then
    health.ok("bat installed")
  else
    health.warn("bat missing — previews won't render with syntax highlighting")
  end

  if vim.fn.executable("git") == 1 then
    health.ok("git installed")
  else
    health.warn("git missing — git features won't work")
  end
end

return M
