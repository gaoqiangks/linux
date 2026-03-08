local plugins = {
    {
        url = "git@github.com:gaoqiangks/registers.nvim.git",
        -- enabled = false,
        cmd = "Registers",
        -- config = true,
        keys = {
            { '"', mode = { "n", "v" } },
            { "<C-R>", mode = "i" },
        },
        name = "registers",
        config = function()
            require("registers").setup({
                window = {
                    -- The window can't be wider than 100 characters
                    -- max_width = 100,
                    -- Show a small highlight in the sign column for the line the cursor is on
                    highlight_cursorline = true,
                    -- Don't draw a border around the registers window
                    border = "single",
                    -- Apply a tiny bit of transparency to the the window, letting some characters behind it bleed through
                    transparency = 0,
                    -- Custom background color for the floating window (hex string like "#1e1e2e" or a highlight group name), nil uses the default
                    background_color = "#ff0000",
                },
            })
        end,
    },
    {
        -- 实时显示RGB值的颜色
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        config = function()
            require("colorizer").setup()
        end,
    },
    {
        -- 没什么用, 编辑大文件的时候, bigfile.nvim会禁用undo之类
        "LunarVim/bigfile.nvim",
        enabled = false,
    },
    {
        "dstein64/vim-startuptime",
        -- luasnip插件会阻塞住StartupTime.
    },
    {
        "HUAHUAI23/nvim-quietlight",
        config = function() end,
    },
    {
        "ayosec/hltermpaste.vim",
    },
    {
        "kdheepak/monochrome.nvim",
    },
    {
        "zaldih/themery.nvim",
        config = function()
            require("themery").setup({
                themes = { {} },
                -- add the config here
            })
        end,
    },
    {
        url = "git@github.com:gaoqiangks/eink",
        enabled = false,
        lazy = true,
        config = function()
            --这样设置的话, Pmenusel没有颜色, 在NvChad中, 应该使用NvChad的theme来配置, 直接使用colorscheme也会被lsp的高亮覆盖
            --vim.cmd("colorscheme " .. g_colorscheme)
        end,
    },
    {
        "google/vim-searchindex",
    },
    {
        "vim-scripts/SyntaxAttr.vim",
    },
    {
        "AndrewRadev/bufferize.vim",
    },
    {
        "kana/vim-altercmd",
        config = function()
            vim.fn["altercmd#load"]()
            vim.cmd("AlterCommand buf Bufferize")
            vim.cmd("AlterCommand explorer Explorer")
        end,
    },
    {
        "Pocco81/auto-save.nvim",
        enabled = false,
        config = function()
            require("auto-save").setup({
                trigger_events = { "InsertLeave" }, -- vim events that trigger auto-save. See :h events
                debounce_delay = 3000, -- saves the file at most every `debounce_delay` milliseconds
            })
        end,
    },
}

return plugins
