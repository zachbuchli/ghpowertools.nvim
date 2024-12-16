local conf = require('telescope.config').values
local pickers = require 'telescope.pickers'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local finders = require 'telescope.finders'
local previewers = require 'telescope.previewers'

local M = {}

-- setup is often used to setup defaults/config for a plugin.
M.setup = function(opts)
  opts = opts or {}

  -- directory to clone git repos into.
  M.git_dir = opts.git_dir or vim.fn.expand '$HOME/git'
  -- extra orgs to be included in repo listings.
  M.orgs = opts.orgs or {}
  -- gh cli --limit flag value.
  M.response_limit = opts.response_limit or 1000
end

---Open a floating window used to display gh cli
---@param cmd string[]
---@param opts? {win?:integer}
function M.show(cmd, opts)
  opts = opts or {}
  -- Create an immutable scratch buffer that is wiped once hidden
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  -- Create a floating window using the scratch buffer positioned in the middle
  local height = math.ceil(vim.o.lines * 0.8) -- 80% of screen height
  local width = math.ceil(vim.o.columns * 0.8) -- 80% of screen width
  local win = vim.api.nvim_open_win(buf, true, {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = math.ceil((vim.o.lines - height) / 2),
    col = math.ceil((vim.o.columns - width) / 2),
    border = 'single',
    ---@diagnostic disable-next-line
    title = opts.title or 'GitHub CLI',
    title_pos = 'center',
  })

  vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf, silent = true, desc = 'buffer local keymap to close floating buf' })
  vim.keymap.set('n', 't', '<C-w>T', { buffer = buf, silent = true, desc = 'buffer local keymap to move buf to new tab' })

  -- Change to the window that is floating to ensure termopen uses correct size
  vim.api.nvim_set_current_win(win)

  vim.fn.termopen { 'gh', unpack(cmd) }
  -- todo: unsure whats best here.
  --vim.cmd.startinsert()
end

--M.show { 'repo', 'list' }

local function str_join(vals, sep)
  local result = vals[1]
  for i = 2, #vals do
    result = result .. sep .. vals[i]
  end
  return result
end

---Call gh cli with cmd and json fields then return results as table.
---@param cmd string[]
---@param fields string[]
---@return table|nil, string?
M.call = function(cmd, fields)
  -- todo: validate fields
  local full_cmd = { 'gh', unpack(cmd) }
  table.insert(full_cmd, '--json')
  table.insert(full_cmd, str_join(fields, ','))

  if M.response_limit then
    table.insert(full_cmd, '--limit')
    table.insert(full_cmd, tostring(M.response_limit))
  end
  local results = vim.system(full_cmd, { text = true }):wait()
  if results.code ~= 0 then
    return nil, results.stderr
  end
  if results.stdout == '' then
    return {}
  end
  local response = vim.json.decode(results.stdout)
  return response
end

-- telescope extension for picking gh repo and cloning to
-- M.git_dir
M.clone_repo = function(opts)
  local results = M.call({ 'repo', 'list' }, { 'name', 'nameWithOwner' })
  if M.orgs then
    for _, v in ipairs(M.orgs) do
      local org_repos = M.call({ 'repo', 'list', v }, { 'name', 'nameWithOwner' })
      vim.list_extend(results or {}, org_repos or {})
    end
  end
  pickers
    .new(opts, {
      prompt_title = 'Clone repo',
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          if entry then
            return {
              value = entry,
              display = entry.nameWithOwner,
              ordinal = entry.nameWithOwner,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local repo = selection.value.nameWithOwner
          local name = selection.value.name
          local dir = M.git_dir .. '/' .. name
          local cmd = { 'gh', 'repo', 'clone', repo, dir }
          vim.notify(string.format('Cloning repo into %s', dir), vim.log.levels.INFO)
          local resp = vim.system(cmd, { text = true }):wait()
          if resp.code ~= 0 then
            vim.notify(resp.stderr, vim.log.levels.ERROR)
            return
          else
            vim.notify(string.format('Changing directory to %s', dir), vim.log.levels.INFO)
            -- change project dir and open dir
            vim.cmd.cd(dir)
            vim.cmd.edit(dir)
          end
        end)
        return true
      end,
    })
    :find()
end

-- telescope extension for picking gh repo and cloning to
-- M.git_dir
M.find_local_repo = function(opts)
  opts = opts or {}
  local results = vim.system({ 'ls', M.git_dir }, { text = true }):wait()
  if results.code ~= 0 then
    vim.notify(results.stderr, vim.logs.levels.ERROR)
    return nil
  end

  local dirs = vim.split(results.stdout, '\n')
  pickers
    .new(opts, {
      prompt_title = 'Select local Git repo',
      finder = finders.new_table {
        results = dirs,
        entry_maker = function(entry)
          if entry then
            return {
              value = entry,
              display = entry,
              ordinal = entry,
            }
          end
        end,
      },

      sorter = conf.generic_sorter(opts),

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local path = M.git_dir .. '/' .. selection.value
          vim.cmd.cd(path)
          vim.cmd.edit(path)
        end)
        return true
      end,
    })
    :find()
end

return M
