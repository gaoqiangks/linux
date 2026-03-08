local get_hl = utils.get_hl
return {
    "gbprod/yanky.nvim",
    dependencies = {
        { "kkharji/sqlite.lua" },
    },
    -- enabled = false,
    --lazy.nvim会调用 require("yanky").setup(opts)
    opts = function()
        local background = ""
        local foreground = ""
        local hl = get_hl("Visual")
        if hl then
            background = hl.background
            foreground = hl.foreground
        end
        if background == "" then
            background = "#a020f0"
        end
        if foreground == "" then
            foreground = "#ffffff"
        end
        if vim.g.vscode then
            background = "#BBBBBB"
            foreground = "#000000"
        end
        vim.api.nvim_set_hl(0, "YankyYanked", { fg = foreground, bg = background })
        vim.api.nvim_set_hl(0, "YankyPut", { fg = foreground, bg = background })
        return {
            ring = {
                storage = "sqlite",
                permanent_wrapper = require("yanky.wrappers").remove_carriage_return,
            },
            highlight = {
                on_put = true,
                on_yank = true,
                timer = 1000,
            },
        }
    end,
    keys = {
        {
            "<leader>p",
            function()
                require("telescope").extensions.yank_history.yank_history({})
            end,
            desc = "Open Yank History",
        },
        {
            "y",
            "<Plug>(YankyYank)",
            mode = { "n", "x" },
            desc = "Yank text",
        },
        {
            "p",
            "<Plug>(YankyPutAfter)",
            mode = { "n", "x" },
            desc = "Put yanked text after cursor",
        },
        {
            "P",
            "<Plug>(YankyPutBefore)",
            mode = { "n", "x" },
            desc = "Put yanked text before cursor",
        },
        -- { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put yanked text after selection" },
        -- { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put yanked text before selection" },
        -- { "<c-p>", "<Plug>(YankyPreviousEntry)", desc = "Select previous entry through yank history" },
        -- { "<c-n>", "<Plug>(YankyNextEntry)", desc = "Select next entry through yank history" },
        {
            "]p",
            "<Plug>(YankyPutIndentAfterLinewise)",
            desc = "Put indented after cursor (linewise)",
        },
        {
            "[p",
            "<Plug>(YankyPutIndentBeforeLinewise)",
            desc = "Put indented before cursor (linewise)",
        },
        {
            "]P",
            "<Plug>(YankyPutIndentAfterLinewise)",
            desc = "Put indented after cursor (linewise)",
        },
        {
            "[P",
            "<Plug>(YankyPutIndentBeforeLinewise)",
            desc = "Put indented before cursor (linewise)",
        },
        {
            ">p",
            "<Plug>(YankyPutIndentAfterShiftRight)",
            desc = "Put and indent right",
        },
        {
            "<p",
            "<Plug>(YankyPutIndentAfterShiftLeft)",
            desc = "Put and indent left",
        },
        {
            ">P",
            "<Plug>(YankyPutIndentBeforeShiftRight)",
            desc = "Put before and indent right",
        },
        {
            "<P",
            "<Plug>(YankyPutIndentBeforeShiftLeft)",
            desc = "Put before and indent left",
        },
        {
            "<a-p>",
            "<Plug>(YankyPutAfterFilter)",
            desc = "Put after applying a filter",
        },
        {
            "<M-p>",
            "<Plug>(YankyPutAfterFilter)",
            desc = "Put after applying a filter",
        },
        {
            "<a-P>",
            "<Plug>(YankyPutBeforeFilter)",
            desc = "Put before applying a filter",
        },
    },
}
