return {
    -- url = "git@github.com:gaoqiangks/mini.notify.git",
    "nvim-mini/mini.notify",
    config = function()
        require("mini.notify").setup({
            window = {
                config = function()
                    local has_tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.fn.gettabinfo() > 1)
                    local has_statusline = vim.o.laststatus > 0

                    -- 计算垂直偏移量，避免遮挡状态栏
                    -- 如果你有特殊的 statusline 或 winbar，可能需要微调 row 的数值
                    local row = vim.o.lines - (has_statusline and 2 or 1)
                    local col = vim.o.columns

                    return {
                        anchor = "SE", -- 设置锚点为右下角
                        row = row,
                        col = col,
                        focusable = false,
                    }
                end,
            },
            -- Notifications about LSP progress
            lsp_progress = {
                -- Whether to enable showing
                enable = false,

                -- Notification level
                level = "INFO",

                -- Duration (in ms) of how long last message should be shown
                duration_last = 1000,
            },
        })
        -- local notify_opts = {
        --     ERROR = { duration = 5000, hl_group = "DiagnosticError" },
        --     WARN = { duration = 5000, hl_group = "DiagnosticWarn" },
        --     INFO = { duration = 5000, hl_group = "DiagnosticInfo" },
        --     DEBUG = { duration = 0, hl_group = "DiagnosticHint" },
        --     TRACE = { duration = 0, hl_group = "DiagnosticOk" },
        --     OFF = { duration = 0, hl_group = "MiniNotifyNormal" },
        -- }
        -- vim.notify = notify.make_notify(notify_opts)
    end,
}
