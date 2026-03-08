local count_qf_types = function()
    local qf_list = vim.fn.getqflist()
    local counts = {
        error = 0,
        warn = 0,
        -- info  = 0,
        -- hint  = 0,
    }

    for _, item in ipairs(qf_list) do
        local t = item.type
        if t == "E" then
            counts.error = counts.error + 1
        elseif t == "W" then
            counts.warn = counts.warn + 1
        end
    end
    return counts
end

-- 示例：打印结果
-- local result = count_qf_types()
-- print(vim.inspect(result))

return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        -- 在状态栏显示copilot的状态
        "AndreM222/copilot-lualine",
        {
            "linrongbin16/lsp-progress.nvim",
            config = function()
                require("lsp-progress").setup()
            end,
        },
    },
    -- lua
    -- lazy=true,
    -- 禁用lualine
    -- enabled = false,
    config = function()
        require("lualine").setup({
            options = {
                -- 无论是否显示图标, 都需要安装nerd-fonts
                -- icons_enabled = false,
                theme = "auto",
                -- component_separators = { left = "", right = "" },
                -- section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = {
                    -- 'copilot',
                    {
                        "diagnostics",
                        sources = { count_qf_types },
                        -- 只有当当前 buffer 是 LaTeX 源文件时才显示诊断信息
                        cond = function()
                            -- 判断当前 buffer 是否是 LaTeX 源文件
                            -- 1. 先看 Neovim 的 filetype
                            local ft = vim.bo.filetype
                            if ft == "tex" or ft == "latex" then
                                return true
                            end

                            -- 2. 再看文件扩展名（更保险）
                            local filename = vim.api.nvim_buf_get_name(0)
                            if filename:match("%.tex$") then
                                return true
                            end

                            return false
                        end,
                        sections = { "error", "warn" },
                        always_visible = true, -- Show diagnostics even if there are none.
                    },
                    -- function()
                    -- return require('lsp-progress').progress()
                    -- end,
                },
                lualine_y = { "location", "progress" },
                lualine_z = { "encoding", "fileformat" },
            },
        })
    end,
}
