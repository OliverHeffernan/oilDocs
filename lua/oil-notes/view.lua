local M = {}
local states = {}

local function valid_window(window)
  return window and vim.api.nvim_win_is_valid(window)
end

local function valid_buffer(buffer)
  return buffer and vim.api.nvim_buf_is_valid(buffer)
end

local function forget(oil_window)
  states[oil_window] = nil
end

local function new_buffer()
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "markdown"
  vim.bo[buffer].modifiable = false
  return buffer
end

local function create_window(oil_window, buffer, config)
  local preview_window

  vim.api.nvim_win_call(oil_window, function()
    if config.split == "vertical" then
      vim.cmd(("belowright %dvsplit"):format(config.width))
    else
      vim.cmd(("belowright %dsplit"):format(config.height))
    end
    preview_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(preview_window, buffer)
  end)

  if valid_window(oil_window) then
    vim.api.nvim_set_current_win(oil_window)
  end

  vim.wo[preview_window].winfixheight = config.split == "horizontal"
  vim.wo[preview_window].winfixwidth = config.split == "vertical"
  vim.wo[preview_window].number = false
  vim.wo[preview_window].relativenumber = false
  vim.wo[preview_window].signcolumn = "no"
  vim.wo[preview_window].foldcolumn = "0"
  vim.wo[preview_window].cursorline = false
  vim.wo[preview_window].wrap = true
  return preview_window
end

function M.show(oil_window, note_path, lines, config)
  if not valid_window(oil_window) then
    return
  end

  local state = states[oil_window] or {}
  local buffer = valid_buffer(state.preview_buffer) and state.preview_buffer or new_buffer()
  local preview_window = valid_window(state.preview_window) and state.preview_window
    or create_window(oil_window, buffer, config)

  if vim.api.nvim_win_get_buf(preview_window) ~= buffer then
    vim.api.nvim_win_set_buf(preview_window, buffer)
  end

  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
  vim.bo[buffer].modified = false
  -- Buffer names must be unique even when two Oil windows show the same note.
  vim.api.nvim_buf_set_name(buffer, ("oil-notes://%d/%s"):format(oil_window, note_path))

  states[oil_window] = {
    preview_window = preview_window,
    preview_buffer = buffer,
    note_path = note_path,
    oil_buffer = vim.api.nvim_win_get_buf(oil_window),
  }
end

function M.close(oil_window)
  local state = states[oil_window]
  if not state then
    return
  end

  forget(oil_window)
  if valid_window(state.preview_window) then
    pcall(vim.api.nvim_win_close, state.preview_window, true)
  end
  if valid_buffer(state.preview_buffer) then
    pcall(vim.api.nvim_buf_delete, state.preview_buffer, { force = true })
  end
end

function M.close_for_buffer(oil_buffer)
  for oil_window, state in pairs(states) do
    if state.oil_buffer == oil_buffer
      and (not valid_window(oil_window) or vim.api.nvim_win_get_buf(oil_window) ~= oil_buffer)
    then
      M.close(oil_window)
    end
  end
end

function M.remove_closed(window)
  local closed = tonumber(window)
  if not closed then
    return
  end
  if states[closed] then
    local state = states[closed]
    forget(closed)
    if valid_window(state.preview_window) then
      pcall(vim.api.nvim_win_close, state.preview_window, true)
    end
  end
  for oil_window, state in pairs(states) do
    if state.preview_window == closed then
      forget(oil_window)
    end
  end
end

function M.note_path(oil_window)
  return states[oil_window] and states[oil_window].note_path or nil
end

function M.is_open(oil_window)
  local state = states[oil_window]
  return state ~= nil and valid_window(state.preview_window)
end

function M.each(callback)
  for oil_window, state in pairs(states) do
    callback(oil_window, state)
  end
end

return M
