local M = {}

-- check will be run with :checkhealth <plugin-name>
-- replace <plugin-name> with the name of your plugin
M.check = function()
  vim.health.start 'ghpowertools'

  if vim.fn.executable 'gh' == 0 then
    vim.health.error 'gh not found on path'
    return
  end

  -- Indicate that we found curl, which is good!
  vim.health.ok 'gh found on path'

  -- Pull the version information about curl
  local results = vim.system({ 'gh', 'version' }, { text = true }):wait()

  -- If we get a non-zero exit code, something went wrong
  if results.code ~= 0 then
    vim.health.error("failed to retrieve gh's version", results.stderr)
    return
  end

  local lines = vim.split(results.stdout, '\n')
  local version = vim.split(lines[1], ' ')[3]
  -- NOTE: While `vim.version.parse` should return nil on invalid input,
  --       having something really invalid like "abc" will cause it to
  --       throw an error on neovim 0.10.0! Make sure you're using 0.10.2!
  local v = vim.version.parse(version or '')
  if not v then
    vim.health.error('invalid gh version output', results.stdout)
    return
  end

  -- Require curl 8.x.x
  if v.major ~= 2 then
    vim.health.error('gh must be 2.x.x, but got ' .. tostring(v))
    return
  end

  -- Curl is a good version, so lastly we'll test the weather site
  vim.health.ok('gh ' .. tostring(v) .. ' is an acceptable version')
end

return M
