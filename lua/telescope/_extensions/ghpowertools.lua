local ghpowertools = require 'ghpowertools'

return require('telescope').register_extension {
  exports = { clone_repo = ghpowertools.clone_repo },
}
