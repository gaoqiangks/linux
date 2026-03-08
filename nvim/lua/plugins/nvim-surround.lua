--lua中， if 0被认为是true.  只有if nil/  if false是false
return {
    {
        url = "git@github.com:gaoqiangks/nvim-surround",
        -- lazy=true,
        config = function()
            local c = require("nvim-surround.config")
            require("nvim-surround").setup({
                move_cursor = false,
                highlight = {
                    -- normal mode下, 比如ysaw, 这个时候会选中当前单词, 并高亮. duration是指的这种高亮持续的时间
                    duration = 0,
                    durationv = 3000,
                },
                aliases = {
                },
                --nvim-surround的操作是可重复的. 比如ysiw", 将一个单词用"引用后, 在下一个单词可以直接按.来重复
                surrounds = {
                    [")"] = {
                        add = function()
                            return { { " \\left( " }, { " \\right) " } }
                        end,
                        find = "(\\left%s*%()().-(\\right%s*%))()",
                        delete = "^(\\left%s*%()().-(\\right%s*%))()$",
                    },
                    ["("] = {
                        add = function()
                            return { { "(" }, { ")" } }
                        end,
                    },
                    ["}"] = {
                        add = function()
                            return { { " \\left\\{ " }, { " \\right\\} " } }
                        end,
                        -- find = "%b{},?",
                        -- delete = "^({)().-(},?)()$",
                        -- find = "(\\left%s*\\{)().-(\\right%s*\\})()",
                        -- delete = "^(\\left%s*\\{)().-(\\right%s*\\})()$",
                        -- find反回两个值, 开始和结束
                        -- find = function()
                        --     local delim_open, delim_close = vim.fn["vimtex#delim#get_surrounding"]("delim_all")
                        --     local firstpos = { delim_open.lnum, delim_open.cnum }
                        --     local lastpos = { delim_close.lnum, delim_close.cnum + string.len(delim_close.match) }
                        --     return { first_pos = firstpos, last_pos = lastpos }
                        -- end
                    },
                    ["{"] = {
                        add = function()
                            return { { "{" }, { "}" } }
                        end,
                        -- delete = function()
                        --     return "aaaa"
                        -- end
                    },
                    ["["] = {
                        add = function()
                            return { { "[" }, { "]" } }
                        end,
                    },
                    ["]"] = {
                        add = function()
                            return { { "[ " }, { " ]" } }
                        end,
                    },
                    ["<"] = {
                        add = function()
                            return { { "<" }, { ">" } }
                        end,
                    },
                    [">"] = {
                        add = { "< " },
                        { " >" },
                    },
                    ["E"] = {
                        add = function()
                            return { { "\\begin{equation}" }, { "\\end{equation}" } }
                        end,
                    },
                    ["T"] = {
                        add = function()
                            return { { "\\begin{theorem}" }, { "\\end{theorem}" } }
                        end,
                    },
                    ["e"] = {
                        add = function()
                            --ySSe 将当前行放在环境中. 比如*eq, 将会放在equation*环境中. eq会放在equation环境中.
                            local env_input = c.get_input("surround输入环境名称:")
                            local final_env = get_env(env_input)
                            if final_env == "" then
                                return nil
                            end
                            return { { "\\begin{" .. final_env .. "}" }, { "\\end{" .. final_env .. "}" } }
                        end,
                    },
                    --ysiwi 将当前单词放在textit环境中
                    --dsi 删除当前的textit命令及其中的文字
                    ["i"] = {
                        add = { "\\textit{", "}" },
                        find = "\\textit%b{}",
                        delete = "^(\\textit{)().-(})()$",
                    },
                    ["1"] = {
                        add = { "\\textbf{", "}" },
                        find = "\\textbf%b{}",
                        delete = "^(\\textbf{)().-(})()$",
                    },
                    --ysiwc 将当前单词放在命令中
                    --vimtex提供了dsc  csc dic等删除, 修改命令等操作, 但是没有提供ys**
                    ["c"] = {
                        add = function()
                            -- local config = require("nvim-surround.config")
                            local cmd_input = c.get_input("surround输入命令名称:")
                            if cmd_input == nil then
                                return
                            end
                            cmd_input = cmd_input:gsub("^\\", "")
                            return { { "\\" .. cmd_input .. "{" }, { "}" } }
                        end,
                    },
                },
            })
            local keyset = vim.keymap.set

            --  di" 删除引号之间的区域
            --  da" 删除引号之间的区域，包含引号
            --  ci" 修改引号之间的区域
            --  ca" 修改引号之间的区域，包含引号
            --  yi" yank引号之间的区域
            --  ya" yank引号之间的区域，包含引号
            --  ysl" 当前字符下加引号
            --  ysaw" 当前单词下加引号
            --  cs"' 双引号修改为单引号

            --keyset("n", "[[", "ysl{ll", {silent=true})
            --keyset("n", "]]", "ysl{ll", {silent=true})
            --将当前行放置在latex环境中, 后面的动作是nvim-surround中定义的.  cse,
            --更改当前环境, 在vimtex中定义
            keyset("n", "44", "ysl$", { silent = true, remap = true })
            keyset("n", "ee", "ySSe", { silent = true, remap = true })
            keyset("n", "EE", "ySSE", { silent = true, remap = true })

            --nvim-surround默认的高亮组是visual, vscode-neovim的文档中说明,
            --默认的高亮组可能会被覆盖, 最好自定义高亮, 而不是link到其它组
            -- if g_notinvscode() then
            --     vim.api.nvim_set_hl(0, "NvimSurroundHighlight", { link = "Visual" })
            -- else
            --     vim.api.nvim_set_hl(0, "NvimSurroundHighlight", { bg = "LightGrey", fg = "Black" })
            -- end
        end,
    },
}
