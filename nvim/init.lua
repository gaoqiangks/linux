keyset = vim.keymap.set
utils = require("lib.utils")
indent = utils.indent
log = utils.log
get_env = utils.get_env
in_wsl = utils.in_wsl
-- alt-r搜索历史, alt-e编辑当前历史行. 如果<alt-q>退出了, 则认为放弃了编辑历史行, 直接退出. 但是如果是:wq退出的, 则认为接受当前编辑
alt_q_exit_code = 0
if utils.is_temporary_buffer() then
    alt_q_exit_code = 1
end
-- 是否是diff模式下启动nvim
-- if vim.opt.diff:get() then
--     alt_q_exit_code = 0
--     -- require("config.keymaps")
--     require("config.options")
--     -- require("config.autocmds")
--     return
-- end

if nvimpager or vim.opt.diff:get() then
    alt_q_exit_code = 0
    require("config.keymaps")
    require("config.options")
    return
end

vim.cmd.source("~/.config/nvim/vim/log.vim")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.cmd_sioyek = "abcd"

-- Setup lazy.nvim
--

local lazy_config = {
    spec = {
        -- 所有插件都在lua/plugins目录下配置. 另外, lua/plugins/vscode.lua文件定义了哪些插件会在vscode-neovim中加载
        -- 如果要调试某个插件的话, 可以参考lua/plugins/enabled.lua文件, 只有在其中的插件才会被加载

        { import = "plugins" },
    },
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        enabled = true,
        notify = false,
        notify_on_write = false,
        notify_on_nvim_reload = false,
    },
    -- ui = { icons = { cmd = "⌘", config = "🛠", event = "📅", ft = "📂", init = "⚙", keys = "🗝", plugin = "🔌", runtime = "💻", require = "🌙", source = "📄", start = "🚀", task = "📌", lazy = "💤 ", }, },
}

if vim.g.vscode then
    vscode = require("vscode-neovim")
end

-- config下面的目录只配置与插件无关的功能. 所有插件相关的选项都在该插件的配置文件中设置
require("config.keymaps")
require("config.options")
require("config.autocmds")
require("config.cmds")

-- require("lazy").setup(lazy_nvim_setup)
require("lazy").setup(lazy_config)

-- vim.cmd.source("~/.config/nvim/vim/test.vim")
-- vim.cmd.source("~/.config/nvim/lua/lib/events.vim")
