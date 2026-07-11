local config_module = require("oilDocs.config")
local notes = require("oilDocs.notes")
local view = require("oilDocs.view")

local M = {}
local config = config_module.resolve()
local hidden = {}

local function oil_directory(buffer)
  local ok, oil = pcall(require, "oil")
  if not ok then
    return nil
  end
  return oil.get_current_dir(buffer)
end

local function current_oil_window()
  local window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_win_get_buf(window)
  if vim.bo[buffer].filetype ~= "oil" then
    return nil
  end
  return window, buffer
end

function M.sync(oil_buffer)
  if not vim.api.nvim_buf_is_valid(oil_buffer) then
    return
  end

  local directory = oil_directory(oil_buffer)
  if not directory then
    return
  end
  local note_path = notes.resolve(directory, config)

  for _, oil_window in ipairs(vim.fn.win_findbuf(oil_buffer)) do
    if hidden[oil_window] then
      view.close(oil_window)
    elseif note_path and notes.exists(note_path) then
      local lines = notes.read(note_path)
      if lines then
        view.show(oil_window, note_path, lines, config)
      else
        view.close(oil_window)
      end
    elseif config.close_when_missing then
      view.close(oil_window)
    end
  end
end

function M.toggle()
  local window, buffer = current_oil_window()
  if not window then
    return
  end
  hidden[window] = not hidden[window]
  if hidden[window] then
    view.close(window)
  else
    M.sync(buffer)
  end
end

function M.open_note()
  local window, buffer = current_oil_window()
  if not window then
    return
  end

  local directory = oil_directory(buffer)
  local path = directory and notes.resolve(directory, config) or nil
  if not path then
    return
  end

  if not notes.exists(path) then
    if not config.create_missing then
      vim.notify("No directory note: " .. path, vim.log.levels.INFO)
      return
    end
    local answer = vim.fn.confirm("Create directory note?", "&Yes\n&No", 2)
    if answer ~= 1 then
      return
    end
    local name = vim.fs.basename(vim.fs.normalize(directory))
    local ok, result = pcall(vim.fn.writefile, { "# " .. name, "" }, path, "x")
    if not ok or result ~= 0 then
      vim.notify("Could not create note: " .. path, vim.log.levels.ERROR)
      return
    end
  end

  hidden[window] = true
  view.close(window)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function set_keymaps(buffer)
  local options = { buffer = buffer, silent = true }
  if config.keymaps.open then
    vim.keymap.set("n", config.keymaps.open, M.open_note, vim.tbl_extend("force", options, {
      desc = "Open directory note",
    }))
  end
  if config.keymaps.toggle then
    vim.keymap.set("n", config.keymaps.toggle, M.toggle, vim.tbl_extend("force", options, {
      desc = "Toggle directory note preview",
    }))
  end
end

local function schedule_sync(oil_buffer)
  if not oil_buffer then
    return
  end
  set_keymaps(oil_buffer)
  vim.schedule(function()
    M.sync(oil_buffer)
  end)
end

function M.setup(options)
  config = config_module.resolve(options)
  local group = vim.api.nvim_create_augroup("OilDocs", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "OilEnter",
    callback = function(args)
      local oil_buffer = args.data and args.data.buf or args.buf
      schedule_sync(oil_buffer)
    end,
  })

  -- OilEnter is emitted when Oil finishes loading a directory buffer. Returning
  -- to a cached directory can skip that event, so BufEnter keeps the preview in
  -- sync when revisiting an existing Oil buffer.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "oil://*",
    callback = function(args)
      schedule_sync(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    pattern = "oil://*",
    callback = function(args)
      vim.schedule(function()
        view.close_for_buffer(args.buf)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      hidden[tonumber(args.match)] = nil
      view.remove_closed(args.match)
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(args)
      local path = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
      view.each(function(oil_window, state)
        if vim.fs.normalize(state.note_path) == path and vim.api.nvim_win_is_valid(oil_window) then
          M.sync(vim.api.nvim_win_get_buf(oil_window))
        end
      end)
    end,
  })

  vim.api.nvim_create_user_command("OilDocsToggle", M.toggle, {
    desc = "Toggle the Oil directory note preview",
    force = true,
  })
end

return M
