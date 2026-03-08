local close_win_or_tab = function()
    vim.api.nvim_command('normal! :')
    local n = vim.fn.winnr("$")
    if n > 1 then
        -- 上面的会出错
        -- vim.api.nvim_cmd("quit")
        vim.cmd({ cmd = 'quit', bang = true })
    else
        vim.cmd({ cmd = 'BufferClose', bang = true })
    end
end
return {
    "romgrk/barbar.nvim",
    enabled = false,
    dependencies = {
        'lewis6991/gitsigns.nvim',    -- OPTIONAL: for git status
        'nvim-tree/nvim-web-devicons' -- OPTIONAL: for file icons
    },
    config = function()
        vim.g.barbar_auto_setup = false -- disable auto-setup
        local keyset = vim.keymap.set
        -- 使用自动命令监听颜色方案的改变
        -- 没什么用, 直接在colorscheme的配置文件中改
        -- vim.api.nvim_create_autocmd("ColorScheme", {
        --     callback = function()
        --         -- 设置当前标签的高亮颜色
        --         vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffffff", bg = "#444444" })
        --     end,
        -- })
        keyset("n", "<A-l>", "<cmd>BufferNext<CR>", { noremap = true, desc = "后一个tab" })
        keyset("n", "<A-h>", "<cmd>BufferPrevious<CR>", { noremap = true, desc = "前一个tab" })
        keyset({ "n", "i", "s", "v", "x" }, "<C-c><C-c>", close_win_or_tab,
            { noremap = true, desc = "前一个tab" })
        require('barbar').setup({
            sidebar_filetypes = {
                -- Use the default values: {event = 'BufWinLeave', text = '', align = 'left'}
                NvimTree = { event = 'BufWinLeave', text = 'File Explorer', align = 'left' },
            },
            filetype = {
                -- Sets the icon's highlight group.
                -- If false, will use nvim-web-devicons colors
                custom_colors = false,

                -- Requires `nvim-web-devicons` if `true`
                enabled = false,
            },
            icons = {
                -- 如果buffon没有设置, 则会在每个buffer的右侧显示一个关闭按钮. 也可以设置buffon = xxx(自定义的图标)
                button = false,
                separator = { left = ' ', right = ' ' },

                -- If true, add an additional separator at the end of the buffer list
                separator_at_end = true,

                -- Configure the icons on the bufferline when modified or pinned.
                -- Supports all the base icon options.
                modified = { button = '*' },
                -- separator = { left = "p", right = "x" },
                -- separator = { left = '+', right = '*' },
            }
        })
    end
}
