return {
    "akinsho/bufferline.nvim",
    enabled = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    event = { "UIEnter" },
    config = function()
        local keyset = vim.keymap.set
        keyset("n", "<A-l>", "<cmd>BufferLineCycleNext<CR>", { noremap = true, desc = "后一个tab" })
        keyset("n", "<A-h>", "<cmd>BufferLineCyclePrev<CR>", { noremap = true, desc = "前一个tab" })
        -- log("bufferline loaded")
        require("bufferline").setup({
            options = {
                themable = true,
                show_clutilse_icon = true,
                -- ordinal
                numbers = "none",
                buffer_clutilse_icon = "",
                modified_icon = "●",
                left_trunc_marker = "",
                right_trunc_marker = "",
                diagnutilstics = "nvim_lsp",
                separator_style = "thin",
                indicator = { icon = "▎", style = "icon" },
                offsets = {
                    {
                        filetype = "NvimTree",
                        text = "File Explorer",
                        highlight = "Directory",
                        text_align = "center",
                    },
                },
            },
            highlights = {
                buffer_selected = {
                    -- fg = "#ffffff",
                    bg = "#444444",
                },
            }
        })
    end,
}

-- function pack.register_maps()
--     utils.map.bulk_register({
--         {
--             mode = { "n" },
--             lhs = "<c-q>",
--             rhs = "<cmd>BufferDelete<cr>",
--             options = { silent = true },
--             description = "Close current buffer",
--         },
--         {
--
--             mode = { "n" },
--             lhs = "<leader>bq",
--             rhs = "<cmd>BufferLinePickClose<cr>",
--             options = { silent = true },
--             description = "Close target buffer",
--         },
--         {
--             mode = { "n" },
--             lhs = "<c-h>",
--             rhs = "<cmd>BufferLineCyclePrev<cr>",
--             options = { silent = true },
--             description = "Go to left buffer",
--         },
--         {
--             mode = { "n" },
--             lhs = "<c-l>",
--             rhs = "<cmd>BufferLineCycleNext<cr>",
--             options = { silent = true },
--             description = "Go to right buffer",
--         },
--         {
--             mode = { "n" },
--             lhs = "<c-e>",
--             rhs = "<cmd>BufferLineMovePrev<cr>",
--             options = { silent = true },
--             description = "Move current buffer to left",
--         },
--         {
--             mode = { "n" },
--             lhs = "<c-y>",
--             rhs = "<cmd>BufferLineMoveNext<cr>",
--             options = { silent = true },
--             description = "Move current buffer to right",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>bn",
--             rhs = "<cmd>enew<cr>",
--             options = { silent = true },
--             description = "Create new buffer",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>bh",
--             rhs = "<cmd>BufferLineCloseLeft<cr>",
--             options = { silent = true },
--             description = "Close all left buffers",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>bl",
--             rhs = "<cmd>BufferLineCloseRight<cr>",
--             options = { silent = true },
--             description = "Close all right buffers",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>bo",
--             rhs = "<cmd>BufferLineCloseOthers<cr>",
--             options = { silent = true },
--             description = "Close all other buffers",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>ba",
--             rhs = function()
--                 vim.cmd("BufferLineCloseOthers")
--                 vim.cmd("BufferDelete")
--             end,
--             options = { silent = true },
--             description = "Close all buffers",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>bt",
--             rhs = "<cmd>BufferLinePick<cr>",
--             options = { silent = true },
--             description = "Go to buffer *",
--         },
--         {
--             mode = { "n" },
--             lhs = "<leader>bs",
--             rhs = "<cmd>BufferLineSortByExtension<cr>",
--             options = { silent = true },
--             description = "Buffers sort (by extension)",
--         },
--     })
-- end
--
-- return pack
