return {
    --官方gelguy的已经不再维护了
    -- 'gelguy/wilder.nvim',
    'lth-go/wilder.nvim',
    enabled = false,
    config = function()
        -- config goes here
        require("wilder").setup({
            modes = { ':', '/', '?' },
            next_key = '<C-p>',
            previous_key = '<C-n>',
            -- accept_key = '<CR>',
            -- reject_key = '<Up>'
        })
    end,
}
