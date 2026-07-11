local M = {}

M.defaults = {
  position = "below",
  height = 12,
  close_when_missing = true,
  create_missing = true,
  keymaps = {
    open = "gN",
    toggle = "gM",
  },
  filename = function(directory, name)
    return vim.fs.joinpath(directory, name .. ".md")
  end,
}

function M.resolve(options)
  local config = vim.tbl_deep_extend("force", {}, M.defaults, options or {})

  if config.position ~= "below" then
    error("oil-notes: position must be 'below'")
  end
  if type(config.height) ~= "number" or config.height < 1 then
    error("oil-notes: height must be a positive number")
  end
  if type(config.filename) ~= "function" then
    error("oil-notes: filename must be a function")
  end

  return config
end

return M
