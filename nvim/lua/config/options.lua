-- 仅用来设置与插件无关的设置
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.showcmd = false
-- vim.opt.history=100000
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 4 -- A TAB character looks like 4 spaces
vim.opt.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.opt.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.opt.shiftwidth = 4 -- Number of spaces inserted when indenting
--自动换行
vim.opt.wrap = true
--显示空格和tab
vim.opt.linebreak = true -- 换行时, 只在单词边界处换行

vim.opt.breakindent = true -- 软换行时, 断行保持与第一行相同的缩进

-- vim.opt.breakindentopt = { "shift:2" }

-- 设置软换行的视觉提示符号
-- vim.opt.showbreak   = "↪ "

vim.opt.list = true
vim.opt.listchars = {
    tab = "→ ", -- 制表符显示为箭头
    space = "·", -- 空格显示为小点
    trail = "•", -- 行尾空格
    extends = "⟩", -- 超出右边界
    precedes = "⟨", -- 超出左边界
    nbsp = "␣", -- 不间断空格
    eol = "↲", --换行符
}
-- vim.opt.listchars = "tab:> ,space:·"
-- vim.opt.listchars   = "tab:> ,eol:↲"
-- vim.opt.listchars   = { tab = "> ", eol = "↲", trail = "~", extends = ">", precedes = "<", nbsp = "⍽" }
-- vim.opt.listchars = { space = '_', tab = '>-'}
--
--自动同步到系统剪贴板
--一定要安装xsel或者wl-clipboard, 否则clipboard.vim会非常的慢
vim.opt.clipboard = "unnamedplus"
-- vim.g.clipboard = "xsel"
-- vim.api.nvim_create_autocmd("VimEnter", {
--     callback = function()
--         vim.opt.clipboard = "unnamedplus"
--     end,
-- })
vim.opt.iskeyword:append("*")
-- defer_fn是一次性的timer. timer会延迟函数的运行.  neovim本身是单线程的, vim.opt.clibboard="unnamedplus"目前肯定会阻塞neovim, 而用timer设置, 至少可以保证neovim在启动的时候没有阻塞, 而是等到启动完成, neovim比较空闲的时候再来执行.
-- function clipboard_set_delayed()
--     vim.defer_fn(function()
--         vim.opt.clipboard = "unnamedplus"
--     end, 0)
-- end
-- clipboard_set_delayed()
-- require("clipboard").setup()

-- nvim-tree插件建议禁用netrw(neovim内置的文件浏览器)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.undofile = true

-- 禁用vim自身的右键菜单
-- vim.opt.mouse = "r"
--启用所有的鼠标功能
vim.opt.mouse = "a"

-- vim.opt.colorscheme="delek"

-- 如果不设置的话, clipboard.vim会自己寻找可用的win32yank.exe, 启动速度会变慢
-- 2026.02.14更新 现在设置了vim.g.clipboard反而会变得很慢, 而且不设置也已经可以自动同步到系统剪贴板了, 所以就注释掉了
-- if in_wsl then
--     vim.g.clipboard = {
--         name = "win32yank-wsl",
--         copy = {
--             ["+"] = "win32yank.exe -i --crlf",
--             ["*"] = "win32yank.exe -i --crlf",
--         },
--         paste = {
--             ["+"] = "win32yank.exe -o --lf",
--             ["*"] = "win32yank.exe -o --lf",
--         },
--         cache_enabled = true,
--     }
-- end
--2026.3.5更新. wslg好像还是不需持primary selection, 总是提示错误. 所以就挺动设置一下.
if in_wsl then
    vim.g.clipboard = {
        name = "wl-copy-wsl",
        copy = {
            ["+"] = "wl-copy --type text/plain",
            ["*"] = "wl-copy --type text/plain",
        },
        paste = {
            ["+"] = "wl-paste --no-newline",
            ["*"] = "wl-paste --no-newline",
        },
        cache_enabled = true,
    }
end
--是否显示标签页. 0:不显示, 1:只有当标签页数量超过1时显示, 2:总是显示
vim.opt.showtabline = 2

-- bufferline.nvim中建议这么做
vim.opt.termguicolors = true

--按:进入命令行模式, 再按<C-f>进入到command-line window时, command-line window窗口的大小
vim.opt.cmdwinheight = 25

vim.g.loaded_matchparen = 1

-- GUI下光标样式定制
vim.opt.guicursor = {
    "n-v-c-sm:block",
    "i-ci-ve:ver25",
    "r-cr-o:hor20",
    "a:blinkwait500-blinkon500-blinkoff500", -- 所有模式启用闪烁参数
}
-- _value = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor",

if vim.g.neovide then
    --如果使用neovide, 禁用所有动画
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0.00
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_scroll_animation_far_lines = 0
    vim.g.neovide_scroll_animation_length = 0.00
    vim.api.nvim_set_keymap("v", "<sc-c>", '"+y', { noremap = true })
    vim.api.nvim_set_keymap("n", "<sc-v>", 'l"+P', { noremap = true })
    vim.api.nvim_set_keymap("v", "<sc-v>", '"+P', { noremap = true })
    vim.api.nvim_set_keymap("c", "<sc-v>", '<C-o>l<C-o>"+<C-o>P<C-o>l', { noremap = true })
    vim.api.nvim_set_keymap("i", "<sc-v>", '<ESC>l"+Pli', { noremap = true })
    vim.api.nvim_set_keymap("t", "<sc-v>", '<C-\\><C-n>"+Pi', { noremap = true })
    -- 将option键设置为meta键
    vim.g.neovide_input_macos_option_key_is_meta = "both"
    -- 字体
    vim.opt.guifont = "Courier New,Source Han Sans CN ExtraLight,Maple Mono Normal NF CN ExtraLight:h24"
    -- vim.opt.guifont = "Courier New:h22,Source Han Sans CN ExtraLight:h20"
    -- vim.opt.guifont = "Courier New,Maple Mono Normal NF CN ExtraLight:h20:#h-slight"
    -- vim.opt.guifont = "Courier New,Sarasa Mono SC ExtraLight:h20:#h-slight"
    -- 增加行距
    vim.opt.linespace = 6
end
