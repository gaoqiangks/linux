-- 类似于vscode的tabout插件, 按tab跳出当前的括号
-- 另外参考 https://github.com/ysmb-wtsg/in-and-out.nvim
return {
    "kawre/neotab.nvim",
    -- enabled = false,
    event = "InsertEnter",
    config = function()
        require("neotab").setup({
            -- tabkey = "<Tab>",
            tabkey = "<A-f>",
            act_as_tab = true, -- fallback to tab, if `tabout` action is not available
            behavior = "nested", ---@type ntab.behavior
            pairs = { ---@type ntab.pair[]
                { open = "(", close = ")" },
                { open = "[", close = "]" },
                { open = "{", close = "}" },
                { open = "'", close = "'" },
                { open = '"', close = '"' },
                { open = "`", close = "`" },
                { open = "<", close = ">" },
            },
            exclude = {},
            -- smart_punctuators = {
            --     enabled = false,
            --     semicolon = {
            --         enabled = false,
            --         ft = { "cs", "c", "cpp", "java" },
            --     },
            --     escape = {
            --         enabled = false,
            --         triggers = {}, ---@type table<string, ntab.trigger>
            --     },
            -- },
        })
    end
}
