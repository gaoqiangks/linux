return {
    -- 按屏幕行滚动, 而不是文本行
    enabled = false,
    "karb94/neoscroll.nvim",
    config = function()
        require("neoscroll").setup({
            hide_cursor = true,
            stop_eof = true,
            respect_scrolloff = true,
            cursor_scrolls_alone = true,
            easing_function = "quadratic",
        })
    end,
}
