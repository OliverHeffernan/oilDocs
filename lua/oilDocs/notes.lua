local M = {}

function M.resolve(directory, config)
  local normalized = vim.fs.normalize(directory)
  local name = vim.fs.basename(normalized)

  if not name or name == "" then
    return nil
  end

  return config.filename(normalized, name)
end

function M.exists(path)
  return path ~= nil and vim.uv.fs_stat(path) ~= nil
end

function M.read(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or nil
end

return M
