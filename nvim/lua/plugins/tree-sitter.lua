return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false, -- last release is way too old and doesn't work on Windows
    build = function()
        local TS = require("nvim-treesitter")
        if not TS.get_installed then
            return
        end
        -- make sure we're using the latest treesitter util
    end,
    event = { "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    opts_extend = { "ensure_installed" },
    ---@alias lazyvim.TSFeat { enable?: boolean, disable?: string[] }
    ---@class lazyvim.TSConfig: TSConfig
    opts = {
        -- LazyVim config for treesitter
        indent = { enable = true }, ---@type lazyvim.TSFeat
        highlight = {
            enable = true,
            disable = {
                "latex",
            }, -- 在这里禁用 latex
        }, ---@type lazyvim.TSFeat
        folds = { enable = true }, ---@type lazyvim.TSFeat
        ensure_installed = {
            "bash",
            "c",
            "diff",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "lua",
            "luadoc",
            "luap",
            "markdown",
            "markdown_inline",
            "printf",
            "python",
            "query",
            "regex",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "xml",
            "yaml",
        },
    },
    ---@param opts lazyvim.TSConfig
    config = function(_, opts)
        local TS = require("nvim-treesitter")

        setmetatable(require("nvim-treesitter.install"), {
            __newindex = function(_, k)
                if k == "compilers" then
                    vim.schedule(function() end)
                end
            end,
        })

        -- some quick sanity checks
        if not TS.get_installed then
            return
        elseif type(opts.ensure_installed) ~= "table" then
            return
        end

        -- setup treesitter
        TS.setup(opts)

        -- install missing parsers
        local install = vim.tbl_filter(function(lang)
            return
        end, opts.ensure_installed or {})

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("lazyvim_treesitter", { clear = true }),
            callback = function(ev)
                local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)

                ---@param feat string
                ---@param query string
                local function enabled(feat, query)
                    local f = opts[feat] or {} ---@type lazyvim.TSFeat
                    return f.enable ~= false and not (type(f.disable) == "table" and vim.tbl_contains(f.disable, lang))
                end

                -- highlighting
                if enabled("highlight", "highlights") then
                    pcall(vim.treesitter.start, ev.buf)
                end

                -- indents
                if enabled("indent", "indents") then
                end

                -- folds
                if enabled("folds", "folds") then
                end
            end,
        })
    end,
}
