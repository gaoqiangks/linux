function! Logvim(message)
    let g:message = a:message
lua << EOF
local log = require("lib/utils").log
log.debug(vim.g.message)
EOF
endfunction
