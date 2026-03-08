return {
    "L3MON4D3/LuaSnip",
    -- luasnip会使startuptime阻塞住.
    -- enabled = false,
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!).
    -- dependencies = { "rafamadriz/friendly-snippets" },
    build = "make install_jsregexp",
    config = function()
        require("luasnip").setup({
            loaders_store_source = true
        })
        -- local ls = require("luasnip")
        -- require("luasnip.loaders.from_vscode").lazy_load()
        -- require("luasnip").log.set_loglevel("debug")
        -- require("luasnip.loaders.from_vscode").load_standalone({path = "/Users/gaoqiang/a.json"})
        -- vim.keymap.set({"i"}, "<Tab>", function() ls.expand() end, {silent = true})
    end
}
