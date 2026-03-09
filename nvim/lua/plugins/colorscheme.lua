return {
    { "rebelot/kanagawa.nvim" },
    {
        "folke/tokyonight.nvim",
        config = function()
            require("tokyonight").setup({
                -- on_colors = function(colors)
                -- log("colors = " .. vim.inspect(colors))
                -- end,
                on_highlights = function(highlights, colors)
                    -- 设置barbar.nvim的当前buffer高亮
                    -- 同时设置tabline中非活动buffer的颜色与tabline中没有tab的部分的颜色相同
                    highlights.BufferCurrent = {
                        fg = "#ffffff",
                        bg = "#555555",
                    }
                    highlights.BufferInactive = {
                        -- bg = "#555555",
                        -- bg = "#000000",
                        -- bg = "#FF0000",
                        -- fg = "#00FF00",
                        bg = colors.bg, -- 使用主题的背景色
                        fg = "#888888", -- 使用灰色作为非活动buffer的前景色
                    }
                    highlights.BufferTabpageFill = {
                        bg = "#000000",
                    }

                    -- TabLIne 是neovim内置的高亮组，表示没有选中的tab的颜色
                    highlights.TabLine = {
                        bg = "#000000",
                        fg = "#aaaaaa",
                    }
                    -- 自动获取 Normal 前景色
                    local fg = colors.fg -- 这是 theme 的前景色

                    -- comment_fade= 0.75表示要将注释颜色设置为前景色的75
                    local comment_fade = 0.75
                    local function dim(hex, factor)
                        local function channel(i)
                            return math.floor(tonumber(hex:sub(i, i + 1), 16) * factor)
                        end
                        local r, g, b = channel(2), channel(4), channel(6)
                        return string.format("#%02x%02x%02x", r, g, b)
                    end

                    -- 设置新的注释颜色
                    highlights.Comment = { fg = dim(fg, comment_fade), italic = true }

                    -- visual_fade= 0.75 表示要将可视模式选中文本的背景颜色设置为前景色的75
                    local visual_fade = 0.35
                    highlights.Visual = {
                        bg = dim(fg, visual_fade),
                        -- bold = true,
                    }
                    -- Telescope的搜索中选中项的高亮
                    -- highlights.TelescopeSelection = {
                    --     -- bg = dim(fg, visual_fade),
                    --     -- bold = true,
                    --     fg = "green",
                    -- }
                    highlights.CopilotSuggestion = highlights.Comment
                end,
                icons = {
                    button = false,
                },
            })
            vim.cmd.colorscheme("tokyonight-night")
        end,
    },
    { "catppuccin/nvim" },
    { "EdenEast/nightfox.nvim" },
    { "uncleTen276/dark_flat.nvim" },
    { "olimorris/onedarkpro.nvim" },
    { "gbprod/nord.nvim" },
    { "ray-x/aurora" },
    { "cpea2506/one_monokai.nvim" },
    { "titanzero/zephyrium" },
    { "nvimdev/zephyr-nvim" },
}
