if vim.g.loaded_fzf then
  return
end

vim.g.loaded_fzf = 1

vim.api.nvim_create_user_command(
  "FzfFiles",
  function()
    require("fzf").files()
  end,
  {}
)
