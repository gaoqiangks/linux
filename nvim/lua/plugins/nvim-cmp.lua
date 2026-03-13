local neotab = require("neotab")
local luasnip = require("luasnip")
local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end
local kind_icons = {
    Text = "",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰇽",
    Variable = "󰂡",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "󰅲",
}
local priority_compare = function(entry1, entry2)
    if entry1.source.name ~= "luasnip" or entry2.source.name ~= "luasnip" then
        return nil
    end
    if
        entry1.completion_item.data
        and entry2.completion_item.data
        and entry1.completion_item.data.priority
        and entry2.completion_item.data.priority
    then
        if entry1.completion_item.data.priority > entry2.completion_item.data.priority then
            return true
        elseif entry1.completion_item.data.priority < entry2.completion_item.data.priority then
            return false
        else
            return nil
        end
    end
    if entry1.completion_item.data and entry1.completion_item.data.priority then
        return true
    end
    return nil
end

local frequency_compare = function(entry1, entry2)
    if (entry1.source.name == "dictionary") and (entry2.source.name ~= "dictionary") then
        return false
    end
    if (entry1.source.name ~= "dictionary") and (entry2.source.name == "dictionary") then
        return true
    end
    if (entry1.source.name == "dictionary") and (entry2.source.name == "dictionary") then
        if entry1.completion_item.frequency > entry2.completion_item.frequency then
            return true
        elseif entry1.completion_item.frequency < entry2.completion_item.frequency then
            return false
        else
            return nil
        end
    end
    return nil
end

return {
    "hrsh7th/nvim-cmp",
    -- enabled = false,
    dependencies = {
        {
            "zbirenbaum/copilot.lua",
        },
        {
            "neovim/nvim-lspconfig",
        },
        {
            "hrsh7th/cmp-nvim-lsp",
        },
        {
            "hrsh7th/cmp-buffer",
            config = function() end,
        },
        {
            "hrsh7th/cmp-path",
        },
        {
            -- "uga-rosa/cmp-dictionary",
            url = "git@github.com:gaoqiangks/cmp-dictionary.git",
            config = function()
                require("cmp_dictionary").setup({
                    -- paths = { "/usr/share/dict/words" },
                    exact_length = 2,
                })
            end,
        },
        {
            "quangnguyen30192/cmp-nvim-ultisnips",
        },
        {
            "L3MON4D3/LuaSnip",
        },
        {
            --自己修改的版本, 每个snippet可以显示该snippet来自哪个文件
            url = "git@github.com:gaoqiangks/cmp_luasnip",
        },
        {
            url = "git@github.com:gaoqiangks/cmp-vimtex.git",
            config = function()
                require("cmp_vimtex").setup({
                    additional_information = {
                        -- info_in_menu如果设置为true, 每一项菜单项会显示更多的信息, 比如\cite时, 会显示参考文献的标题等等
                        info_in_menu = false,
                    },
                })
            end,
        },
        {
            "windwp/nvim-autopairs",
            event = "InsertEnter",
            config = true,
            -- use opts = {} for passing setup options
            -- this is equivalent to setup({}) function
        },
    },
    config = function()
        -- log.debug("nvim-cmp.lua: config 开始")
        -- Set up nvim-cmp.
        local cmp = require("cmp")
        -- 这个变量用来记录是否因为接受了copilot建议而临时禁用cmp的时间, 默认200ms
        if not cmp_disabled_time_by_copilot then
            cmp_disabled_time_by_copilot = 500
        end
        -- 针对 Telescope 窗口禁用 nvim-cmp
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "TelescopePrompt",
            callback = function()
                cmp.setup.buffer({ enabled = false })
            end,
        })

        -- vim.api.nvim_create_autocmd("InsertCharPre", {
        --     callback = function()
        --         -- log.debug("InsertCharPre triggered, resetting cmp_disabled_by_copilot")
        --         vim.b.cmp_disabled_by_copilot = false
        --     end,
        -- })
        -- local cmp_disabled_time_by_copilot = 200
        local copilot_suggestion = require("copilot.suggestion")
        local next_item = cmp.mapping({
            c = function()
                if cmp.visible() then
                    cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                else
                    vim.api.nvim_feedkeys(t("<Down>"), "n", true)
                end
            end,
            i = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                else
                    fallback()
                end
            end,
        })
        local prev_item = cmp.mapping({
            c = function()
                if cmp.visible() then
                    cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                else
                    vim.api.nvim_feedkeys(t("<Up>"), "n", true)
                end
            end,
            i = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                else
                    fallback()
                end
            end,
        })
        local mapping_basic = {
            ["<Down>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { "i" }),
            ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { "i" }),
            ["<C-n>"] = next_item,
            ["<C-p>"] = prev_item,
            ["<A-n>"] = next_item,
            ["<A-p>"] = prev_item,
            -- ["<C-n>"] = cmp.mapping({
            --     c = function()
            --         if cmp.visible() then
            --             cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            --         else
            --             vim.api.nvim_feedkeys(t("<Down>"), "n", true)
            --         end
            --     end,
            --     i = function(fallback)
            --         if cmp.visible() then
            --             cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            --         else
            --             fallback()
            --         end
            --     end,
            -- }),
            -- ["<C-p>"] = cmp.mapping({
            --     c = function()
            --         if cmp.visible() then
            --             cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
            --         else
            --             vim.api.nvim_feedkeys(t("<Up>"), "n", true)
            --         end
            --     end,
            --     i = function(fallback)
            --         if cmp.visible() then
            --             cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
            --         else
            --             fallback()
            --         end
            --     end,
            -- }),
            ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
            ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
            ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
            ["<C-e>"] = cmp.mapping({ i = cmp.mapping.close(), c = cmp.mapping.close() }),
            ["<CR>"] = cmp.mapping({
                i = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
            }),
        }
        local mapping_luasnip_specific = {
            ["<Tab>"] = cmp.mapping(function(fallback)
                if luasnip.locally_jumpable(1) then
                    luasnip.jump(1)
                    -- 优先级 1: 如果有代码片段可以展开，则展开
                    -- log.debug("expanding luasnip snippet")
                elseif cmp.visible() then
                    -- 优先级 2: 如果补全菜单可见，确认补全 (select = true 表示自动选中第一个)
                    cmp.confirm({ select = true })
                    -- log.debug("confirming cmp item")
                elseif copilot_suggestion.is_visible() then
                    -- 优先级 3: 如果 Copilot 的 AI 建议可见，接受建议
                    -- log.debug("accepting copilot suggestion")
                    -- 接受copilot建议后的200ms内禁用cmp
                    vim.b.cmp_disabled_by_copilot = true
                    vim.defer_fn(function()
                        vim.b.cmp_disabled_by_copilot = false
                    end, cmp_disabled_time_by_copilot)
                    copilot_suggestion.accept()
                else
                    -- 优先级 4: 以上皆无，执行 Tabout 的逻辑
                    -- fallback() 会自动触发 tabout.nvim 注册的 Tab 映射
                    -- log.debug("tab out")
                    neotab.tabout()
                end
            end, { "i", "s" }),
            ["<A-e>"] = cmp.mapping(function(fallback)
                if copilot_suggestion.is_visible() then
                    -- 接受copilot建议后的200ms内禁用cmp
                    vim.b.cmp_disabled_by_copilot = true
                    vim.defer_fn(function()
                        vim.b.cmp_disabled_by_copilot = false
                    end, cmp_disabled_time_by_copilot)

                    -- 优先级 3: 如果 Copilot 的 AI 建议可见，接受建议
                    copilot_suggestion.accept()
                else
                    neotab.tabout()
                end
            end, { "i", "s" }),
            ["<A-w>"] = cmp.mapping(function(fallback)
                if copilot_suggestion.is_visible() then
                    -- 接受copilot建议后的200ms内禁用cmp
                    vim.b.cmp_disabled_by_copilot = true
                    vim.defer_fn(function()
                        vim.b.cmp_disabled_by_copilot = false
                    end, cmp_disabled_time_by_copilot)

                    -- 优先级 3: 如果 Copilot 的 AI 建议可见，接受建议
                    copilot_suggestion.accept_word()
                else
                    neotab.tabout()
                end
            end, { "i", "s" }),
            ["<A-h>"] = cmp.mapping(function(fallback)
                if luasnip.locally_jumpable(-1) then
                    luasnip.jump(-1)
                end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.locally_jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { "i", "s" }),
        }
        local mapping_luasnip = vim.tbl_extend("force", mapping_basic, mapping_luasnip_specific)
        local compare = cmp.config.compare
        cmp.setup({
            enabled = function()
                -- log.debug("checking if cmp should be enabled, cmp_disabled_by_copilot = " .. tostring(vim.b.cmp_disabled_by_copilot))
                if vim.b.cmp_disabled_by_copilot then
                    return false
                end
                return true
            end,
            performance = {
                max_view_entries = 20,
            },
            view = {
                entries = "custom", -- can be "custom", "wildmenu" or "native"
                -- entries = "wildmenu"
                -- entries = "native"
            },
            -- 自动选择第一个补全项
            completion = {
                completeopt = "menu,menuone,noinsert",
            },
            matching = {
                disallow_symbol_nonprefix_matching = false,
            },
            sorting = {
                -- comparators内置了几个排序函数, 可以直接使用
                comparators = {
                    frequency_compare,
                    compare.exact,
                    compare.offset,
                    -- compare.recently_used,
                    compare.score,
                    priority_compare,
                    compare.locality,
                    compare.kind,
                    compare.length,
                    compare.order,
                },
            },
            formatting = {
                -- 补全窗口要显示的字段
                fields = { "abbr", "kind", "menu" },
                -- 这个函数用来格式化补全窗口的每一项
                format = function(entry, vim_item)
                    local source = entry.source.name
                    if source == "luasnip" then
                        vim_item.menu = entry.completion_item.labelDetails and entry.completion_item.labelDetails.source
                            or "luasnip"
                    else
                        -- vim_item.menu = entry.source.name
                        vim_item.menu = ({
                            buffer = "[Buffer]",
                            dictionary = "[Dictionary]",
                            path = "[Path]",
                            nvim_lsp = "[LSP]",
                            luasnip = vim_item.menu,
                            nvim_lua = "[Lua]",
                            latex_symbols = "[LaTeX]",
                            ultisnips = "[UltiSnips]",
                            vimtex = "[VimTex]",
                            -- cmdline_history = "[History]"
                        })[entry.source.name]
                    end
                    -- if source == "dictionary" then
                    --     -- log("entry = " .. vim.inspect(entry))
                    --     vim_item.menu = tostring(entry.completion_item.frequency)
                    -- end
                    vim_item.kind = string.format("%s", kind_icons[vim_item.kind] or "")
                    return vim_item
                end,
            },
            snippet = {
                expand = function(args)
                    -- log("args= " .. vim.inspect(args))
                    local indent_nodes = true
                    if vim.api.nvim_get_option_value("filetype", { buf = 0 }) == "dart" then
                        indent_nodes = false
                    end
                    require("luasnip").lsp_expand(args.body, {
                        indent = indent_nodes,
                    })
                end,
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },

            mapping = mapping_luasnip,
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                -- { name = 'vsnip' }, -- For vsnip users.
                { name = "luasnip" }, -- For luasnip users.
                -- { name = "ultisnips" }, -- For ultisnips users.
                -- { name = 'snippy' }, -- For snippy users.
                {
                    name = "buffer",
                    options = {
                        -- Get buffer source to work with nvim-cmp
                        keyword_length = 4, -- The minimum length of a word to be considered for completion
                    },
                },
                { name = "path" },
                { name = "vimtex" },
                {
                    name = "dictionary",
                    keyword_length = 2,
                },
            }),
        })
    end,
}
