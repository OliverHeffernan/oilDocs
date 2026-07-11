local M = {}

M.defaults = {
  split = "horizontal",
  height = 12,
  width = 48,
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

  if config.split ~= "horizontal" and config.split ~= "vertical" then
    error("oilDocs: split must be 'horizontal' or 'vertical'")
  end
  if type(config.height) ~= "number" or config.height < 1 then
    error("oilDocs: height must be a positive number")
  end
  if type(config.width) ~= "number" or config.width < 1 then
    error("oilDocs: width must be a positive number")
  end
  if type(config.filename) ~= "function" then
    error("oilDocs: filename must be a function")
  end

  return config
end

return M
