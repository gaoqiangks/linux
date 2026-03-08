-- local api = require('Comment.api')
-- api.uncomment()
return {
    url = "git@github.com:gaoqiangks/Comment.nvim",
    opts = function()
        -- Lua
        local api = require('Comment.api')

        -- Toggle selection (linewise)
        vim.keymap.set('x', 'guc', function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false)
            api.uncomment.linewise(vim.fn.visualmode())
        end)
        require('Comment.config'):set(
            {
                force_uncomment = true
            }
        )
    end,
    lazy=true,
}
