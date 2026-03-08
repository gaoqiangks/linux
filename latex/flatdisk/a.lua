local highlight_time = 2000 -- 默认高亮时间为 2000 毫秒（2 秒）

-- 淡出效果函数
local function fade_out_highlight(row)
    local fade_colors = {
        "#555555",
        "#525252",
        "#4e4e4e",
        "#4b4b4b",
        "#484848",
        "#454545",
        "#424242",
        "#3f3f3f",
        "#3c3c3c",
        "#393939",
        "#363636",
        "#333333",
        "#303030",
        "#2d2d2d",
        "#2a2a2a",
        "#272727",
        "#242424",
        "#212121",
        "#1e1e1e",
        "#1b1b1b",
        "NONE",
    }
    local delay = 25 -- 每个颜色的过渡时间间隔为 50 毫秒

    for i, color in ipairs(fade_colors) do
        vim.defer_fn(function()
            vim.cmd("highlight TempHighlight guibg=" .. color)
            vim.api.nvim_buf_clear_namespace(0, -1, row - 1, row)
            if color ~= "NONE" then
                vim.api.nvim_buf_add_highlight(0, -1, "TempHighlight", row - 1, 0, -1)
            end
        end, delay * i)
    end
end

-- 高亮当前行，并在指定时间后触发淡出效果
local function highlight_current_line_with_fade()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_add_highlight(0, -1, "TempHighlight", row - 1, 0, -1)

    -- 根据高亮时间变量触发淡出效果
    vim.defer_fn(function()
        fade_out_highlight(row)
    end, highlight_time)
end

-- 定义高亮组
vim.cmd([[highlight TempHighlight guibg=#555555]])

highlight_current_line_with_fade()
