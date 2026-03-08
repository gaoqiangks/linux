return {
    {
        "smoka7/hop.nvim",
        -- url = "git@github.com:gaoqiangks/hop.nvim.git",
        -- lazy = true,
        config = function()
            require("hop").setup({
                --uppercase_labels = true,
                --one_letter_labels = true,
                create_hl_autocmd = true,
                -- case_insensitive = false,
            })

            -- place this in one of your configuration file(s)
            local hop = require("hop")
            local directions = require("hop.hint").HintDirection
            -- keymap中, "x"和"v"的区别在于, "v"也会映射select mode. 一般情况下这不是我们想要的, 比如自动补全的时候, \newcommand{$1}{$2}, 这个时候光标在$1的位置就是select mode. 如果我们映射了select mode下的f, 那么光标在$1的时候我们就没有办法直接输入f
            vim.keymap.set({ "n", "x" }, "f", function()
                hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
            end, { remap = true })
            vim.keymap.set({ "n", "x" }, "F", function()
                hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
            end, { remap = true })
            vim.keymap.set({ "n", "x" }, "t", function()
                hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false, hint_offset = -1 })
            end, { remap = true })
            vim.keymap.set({ "n", "x" }, "T", function()
                hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 })
            end, { remap = true })
            local set_highlight = function()
                -- augroup 创建了一个组, 在这个组内调用autocmd!可以删除组内的所有autocmd, 省去很多麻烦. 如果没有在一个augroup中, 就得一个一个地删. 当然, 如果不删的话, 只要配置文件没有被source多次, 也没什么问题.
                vim.api.nvim_command("augroup HopInitHighlight")
                vim.api.nvim_command("autocmd!")
                local hop_highlight_setup = function()
                    -- vim.api.nvim_command('augroup HopInitHighlight')
                    vim.api.nvim_command("autocmd!")
                    -- Hop.nvim 高亮设置
                    vim.api.nvim_set_hl(0, "HopNextKey", {
                        fg = "#ff6b6b", -- 鲜明红色，主提示字符
                        -- bg = "#1e1e2e", -- 背景融合色（可选）
                        bold = true,
                    })

                    vim.api.nvim_set_hl(0, "HopNextKey1", {
                        fg = "#f9cb40", -- 明亮黄色，第二提示字符
                        bold = true,
                    })

                    vim.api.nvim_set_hl(0, "HopNextKey2", {
                        fg = "#40c4f9", -- 清爽蓝色，第三提示字符
                        bold = true,
                    })

                    vim.api.nvim_set_hl(0, "HopUnmatched", {
                        fg = "#5c5f77", -- 暗灰色，非匹配字符
                        bg = "#1e1e2e", -- 背景融合色
                    })
                    -- vim.api.nvim_command("highlight clear HopUnmatched")
                end
                local hop_highlight_setup_vscode = function()
                    vim.api.nvim_command("highlight HopNextKey ctermfg=White ctermbg=Black guifg=White guibg=Black")
                    vim.api.nvim_command("highlight HopNextKey1 ctermfg=White ctermbg=Black guifg=White guibg=Black")
                    vim.api.nvim_command("highlight HopNextKey2 ctermfg=White ctermbg=Black guifg=White guibg=Black")
                    vim.api.nvim_command("highlight clear HopUnmatched")
                end
                if vim.g.vscode then
                    -- hop_highlight_setup_vscode()
                    hop_highlight_setup()
                else
                    hop_highlight_setup()
                end
                vim.api.nvim_command("augroup end")
            end

            -- 因为某些主题会重置高亮，可以使用 ColorScheme 自动命令来锁定颜色
            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "*",
                callback = function()
                    set_highlight()
                end,
            })
        end,
    },
}
