return {
    "stevearc/conform.nvim",
    -- enabled = false,
    config = function()
        log.debug("conform.lua: config 开始")
        local opts = function()
            -- Stylua 配置表
            local stylua_cfg = {
                indent_type = "Spaces",
                indent_width = 4,
                column_width = 120,
                line_endings = "Unix",
                quote_style = "AutoPreferDouble",
                call_parentheses = "Always",
            }

            -- 将 stylua 配置转换成 CLI 参数
            local function stylua_args()
                local args = {}
                for k, v in pairs(stylua_cfg) do
                    table.insert(args, "--" .. k:gsub("_", "-") .. "=" .. tostring(v))
                end
                table.insert(args, "-") -- ⭐ 必须加这个，否则 stylua 会报错
                return args
            end

            return {
                -- 保存时自动格式化
                format_on_save = function(bufnr)
                    log.debug("conform.lua: 触发保存时格式化，bufnr =", tostring(bufnr))
                    return {
                        timeout_ms = 3000,
                        lsp_fallback = true,
                    }
                end,

                formatters_by_ft = {
                    lua = { "stylua" },
                },

                formatters = {
                    stylua = {
                        command = "stylua",
                        args = stylua_args,
                        stdin = true,
                    },
                },
            }
        end

        require("conform").setup(opts())

        vim.api.nvim_create_user_command("Format", function()
            log.debug("conform.lua: Format 命令执行")
            require("conform").format()
        end, { desc = "Format current buffer with conform.nvim" })
    end,
}
