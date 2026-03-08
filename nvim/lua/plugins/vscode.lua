if not vim.g.vscode then
    return {}
end

--在vscode中, 只有这个表中的插件会被加载
--****需要注意, 每个插件所依赖的插件也要手动加载****
local enabled = {
    "dial.nvim",
    "flit.nvim",
    "lazy.nvim",
    "sqlite.lua",
    "leap.nvim",
    "mini.ai",
    "mini.comment",
    "mini.move",
    "mini.pairs",
    "mini.surround",
    "nvim-treesitter",
    "nvim-treesitter-textobjects",
    "nvim-ts-context-commentstring",
    "ts-comments.nvim",
    "vim-repeat",
    "yanky.nvim",
    "nvim-surround",
    "Comment.nvim",
    "hop.nvim",
    "vimtex",
    "bufferize.vim",
    "vim-altercmd",
}
local config = require("lazy.core.config")
config.options.defaults.cond = function(plugin)
    return vim.tbl_contains(enabled, plugin.name) or plugin.vscode
end
return {}
