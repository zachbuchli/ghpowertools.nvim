local ghpowertools = require 'ghpowertools'

return require('telescope').register_extension {
  exports = {
    clone_repo = ghpowertools.clone_repo,
    find_local_repo = ghpowertools.find_local_repo,
  },
}
