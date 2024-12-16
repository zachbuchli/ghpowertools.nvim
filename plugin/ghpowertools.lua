vim.api.nvim_create_user_command('GH', function(opts)
  require('ghpowertools').show(opts.fargs)
end, {
  nargs = '+',
  desc = ':GH <cmds> displays results of gh cli in floating window.',
})
