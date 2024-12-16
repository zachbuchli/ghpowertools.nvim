# ghpowertools.nvim

Neovim Power Tools for Neovim.


## Installation
```lua
{
  'zachbuchli/ghpowertools.nvim',
  config = function()
    local themes = require 'telescope.themes'
    local telescope = require 'telescope'
    local ghpowertools = require 'ghpowertools'

    ghpowertools.setup { orgs = { 'cirrusaircraft' } }

    telescope.load_extension 'ghpowertools'

    vim.keymap.set('n', '<leader>gc', function()
      telescope.extensions.ghpowertools.clone_repo(themes.get_dropdown {})
    end, { desc = 'Opens picker for cloning gh repo. Clones repo then changes cwd to selection.' })

    vim.keymap.set('n', '<leader>gs', function()
      telescope.extensions.ghpowertools.find_local_repo(themes.get_dropdown {})
    end, { desc = 'Opens picker for selecting local git repo. Changes cwd to selection.' })
  end,
}
```

