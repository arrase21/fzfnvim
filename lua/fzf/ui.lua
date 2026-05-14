local config = require("fzf.config")
local M = {}

function M.get_fzf_base()
  return "fzf " .. table.concat(config.options.fzf.base, " ")
end

function M.get_preview_cmd()
  return config.options.preview.command .. " " .. config.options.preview.opts
end

function M.get_size()
  local opts = config.options.ui

  local width = math.floor(vim.o.columns * opts.width)

  local height = math.floor(vim.o.lines * opts.height)

  return width, height
end

function M.create_backdrop()
  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    focusable = false,
    style = "minimal",
    zindex = 1,
  })

  vim.api.nvim_set_hl(0, "MyFzfBackdrop", {
    bg = config.options.ui.backdrop_bg,
  })

  vim.api.nvim_win_set_option(win, "winhighlight", "Normal:MyFzfBackdrop")

  vim.api.nvim_win_set_option(win, "winblend", 70)

  return win
end

function M.fzf_ui(cmd, on_select, win_opts)
  local backdrop

  if config.options.ui.backdrop then
    backdrop = M.create_backdrop()
  end

  local buf = vim.api.nvim_create_buf(false, true)

  local width, height, row, col

  if win_opts then
    width = win_opts.width or math.floor(vim.o.columns * config.options.ui.width)
    height = win_opts.height or math.floor(vim.o.lines * config.options.ui.height)
    row = win_opts.row or math.floor((vim.o.lines - height) / 2)
    col = win_opts.col or math.floor((vim.o.columns - width) / 2)
  else
    width, height = M.get_size()
    row = math.floor((vim.o.lines - height) / 2)
    col = math.floor((vim.o.columns - width) / 2)
  end

  local border = (win_opts and win_opts.border) or config.options.ui.border or "rounded"
  local title = (win_opts and win_opts.title) or config.options.ui.title or " FZF "
  local title_pos = (win_opts and win_opts.title_pos) or config.options.ui.title_pos or "center"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = border,
    style = "minimal",
    zindex = 50,
    title = title,
    title_pos = title_pos,
  })

  local root = vim.fn.getcwd()

  local temp = vim.fn.tempname()

  local full_cmd =
    string.format("cd %s && %s > %s", vim.fn.shellescape(root), cmd, vim.fn.shellescape(temp))

  vim.fn.termopen({ "sh", "-c", full_cmd }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end

        if backdrop and vim.api.nvim_win_is_valid(backdrop) then
          vim.api.nvim_win_close(backdrop, true)
        end

        if code == 0 and vim.fn.filereadable(temp) == 1 then
          local f = io.open(temp, "r")

          if f then
            local selection = f:read("*all"):gsub("\n$", "")

            f:close()

            os.remove(temp)

            if selection ~= "" and on_select then
              on_select(selection, root)
            end
          end
        end
      end)
    end,
  })

  vim.keymap.set("t", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end

    if backdrop and vim.api.nvim_win_is_valid(backdrop) then
      vim.api.nvim_win_close(backdrop, true)
    end
  end, {
    buffer = buf,
    nowait = true,
  })

  vim.cmd("startinsert!")
end

return M
