-- 仅用来设置与插件无关的快捷键

keyset("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
keyset("i", "<C-e>", "<End>", { desc = "move end of line" })
keyset("i", "<C-h>", "<Left>", { desc = "move left" })
keyset("i", "<C-l>", "<Right>", { desc = "move right" })
keyset("i", "<C-j>", "<Down>", { desc = "move down" })
keyset("i", "<C-k>", "<Up>", { desc = "move up" })
-- <C-o> 在插入模式下执行一条normal命令, 并且不会退出插入模式
keyset("i", "<A-u>", "<C-o>u", { desc = "插入模式下撤销一次编辑" })
keyset("i", "<A-r>", "<C-o><C-r>", { desc = "插入模式下恢复上一次撤销的编辑" })

keyset("n", "<Esc>", "<cmd>noh<CR>", { noremap = true, desc = "清除高亮" })

keyset({ "n", "i" }, "<C-s>", "<cmd>w<CR>", { noremap = true, desc = "保存文件" })
-- keyset("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })
-- keyset("n", "<C-g>", "1<C-g>", { noremap = true, desc = "显示当前文件和路径" })

keyset({ "n", "v" }, "0", "^", { desc = "交换0和^" })
keyset({ "n", "v" }, "^", "0", { desc = "交换0和^" })
keyset("n", "<A-f>", "V<cmd>Neoformat<CR><Esc>", { noremap = true, desc = "格式化当前行" })
keyset("x", "<A-f>", "<cmd>Neoformat<CR><Esc>", { noremap = true, desc = "格式化选中的行" })
-- 用了bufferline后, tab相关的都在bufferline中设置
-- keyset("n", "<A-h>", "<cmd>tabprev<CR>", { noremap = true, desc = "前一个tab" })
-- keyset("n", "<A-l>", "<cmd>tabnext<CR>", { noremap = true, desc = "后一个tab" })
--
keyset("n", "gp", "`[v`]", { noremap = true, desc = "选中粘贴的文本" })
-- keyset("i", "jk", "<ESC>", { noremap=true, desc = "jk 退出插入模式" })

keyset("n", "<c-g>", "1<c-g>", { noremap = true, desc = "显示当前文件的绝对路径" })

keyset("n", "<A-H>", "<C-w>h", { noremap = true, desc = "左侧的窗口" })
keyset("n", "<A-L>", "<C-w>l", { noremap = true, desc = "右侧的窗口" })
keyset("n", "<A-J>", "<C-w>j", { noremap = true, desc = "下侧的窗口" })
keyset("n", "<A-K>", "<C-w>k", { noremap = true, desc = "上侧的窗口" })
keyset("n", "<A-w>", "<C-w><C-w>", { noremap = true, desc = "切换窗口" })
keyset("n", "<C-c><C-c>", "<Esc><cmd>q!<CR>", { desc = "退出" })
keyset("n", "<A-c><A-c>", "<Esc><cmd>q!<CR>", { desc = "退出" })

-- 设置快捷键
keyset("n", "<C-a>", function()
    local result = utils.copy_entire_file()
    vim.notify(string.format("📋 Copied %d lines (%d chars)", result.lines, result.chars), vim.log.levels.INFO)
end, { noremap = true, silent = true })

-- keyset("n", "<leader>P", ":%d | put +<CR>")
-- keyset("n", "<leader>P", ":%d | read +<CR>")
--
-- 用剪贴板的内容替换当前buffer的内容
vim.keymap.set("n", "<leader>P", ":%d | 0put +<CR>")

-- keyset({ "n", "i", "x", "c" }, "<A-q>", "<Esc><cmd>qa!<CR>", { desc = "退出" })
-- 映射 <A-q> 为放弃编辑并以退出码 1 退出
keyset(
    { "n", "i", "x", "c" },
    "<A-q>",
    "<Esc><cmd>cquit" .. alt_q_exit_code .. "<CR>",
    { desc = "放弃编辑并退出" }
)

keyset("n", "<A-l>", "<cmd>tabnext<CR>", { noremap = true, desc = "后一个tab" })
keyset("n", "<A-h>", "<cmd>tabprev<CR>", { noremap = true, desc = "前一个tab" })
-- keyset({ "n", "i", "x", "c" }, "<M-q>", "<Esc><cmd>qa!<CR>", { desc = "退出" })

-- keyset("n", "<A-p>", "<cmd>lua indent.paste_and_indent('below')<CR>", { silent = true, remap=false})
-- keyset("n", "<A-P>", "<cmd>lua indent.paste_and_indent('above')<CR>", { silent = true, remap=false})

--使用了barbar或者bufferline后, 这两个快捷键就没用了. 因为barbar及其bufferline中的tab实际上是buffer, 而不是vim的tab. 因此在barbar/bufferline中, 执行:q<cr>实际上会退出vim, 而不是退出当前的buffer.
-- keyset("n", "<A-h>", "<cmd>tabprev<CR>", { noremap = true, desc = "前一个tab" })
-- keyset("n", "<A-l>", "<cmd>tabnext<CR>", { noremap = true, desc = "后一个tab" })
-- 用鼠标选中时自动复制到系统剪贴板
keyset("v", "<LeftRelease>", '"*ygv', { noremap = true, desc = "复制选中的文本到系统剪贴板" })
keyset("v", "<2-LeftRelease>", '"*ygv', { noremap = true, desc = "复制选中的文本到系统剪贴板" })

-- keyset("n", "<A-c>", ":<C-f>", { noremap = true, desc = "命令行模式" })
vim.cmd("map <A-k> :<C-f>")

-- 在 Visual 模式下映射 <A-s> 调用上面的函数
vim.keymap.set("v", "<A-s>", function()
    -- 退出 Visual 模式再执行函数
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    utils.search_visual_selection()
end, { noremap = true, silent = true })

-- Normal 模式：删除光标左侧字符，不写入寄存器
-- vim.keymap.set("n", "X", '"_dh', { noremap = true, silent = true })

-- Visual 模式：删除选区，不写入寄存器
vim.keymap.set("x", "X", '"_d', { noremap = true, silent = true })

-- 绑定快捷键，例如 <leader>bc
vim.keymap.set("n", "<leader>bc", "<cmd>BufClear<CR>", { desc = "清空当前 buffer，不覆盖寄存器" })
vim.keymap.set("n", "<A-S-d>", "<cmd>BufClear<CR>", { desc = "清空当前 buffer，不覆盖寄存器" })

local vscode_keymap_setup = function()
    keyset("x", "==", function()
        vscode.call("editor.action.reindentselectedlines")
    end, { silent = true })
    -- keyset("n", "<A-p>", "<cmd>lua vim.api.nvim_exec2(vim.api.nvim_replace_termcodes('normal o<Esc>p', true, false, true), {output=false})<CR><cmd>lua vim.cmd.normal('`[v`]')<CR><cmd>lua vscode.call('editor.action.reindentselectedlines')<CR><Esc>", {silent=true,remap=false, desc= "粘贴到下一行"})

    -- local yank_paste_select = function(arg)
    --     if arg == "above" then
    --         vim.api.nvim_exec2(vim.api.nvim_replace_termcodes("normal O<Esc>p", true, false, true), { output = false })
    --     else
    --         vim.api.nvim_exec2(vim.api.nvim_replace_termcodes("normal o<Esc>p", true, false, true), { output = false })
    --         -- vim.api.nvim_exec2(vim.api.nvim_replace_termcodes("normal ]p", true, false, true), {output=false})
    --     end
    --     --选中刚刚粘贴的内容
    --     vim.cmd.normal("`[v`]")
    --     -- vscode.call('editor.action.setSelectionAnchor')
    --     -- vscode.eval('vscode.commands.executeCommand("cursorMove", { to: "viewPortTop"})')
    --     -- vim.uv.sleep(20)
    --     -- vim.cmd.normal(vim.api.nvim_replace_termcodes('<Esc>', true, true, true))
    --     -- vim.uv.sleep(20)
    --     -- vscode.eval("vscode.commands.executeCommand('cursorMove', { to: 'viewPortTop'})")
    --     -- vim.cmd.normal(vim.api.nvim_replace_termcodes('<Esc>', true, true, true))
    --     -- vim.cmd.normal('`]')
    --     -- vim.cmd.normal('jjj')
    --     -- vscode.call('editor.action.selectFromAnchorToCursor')
    --     -- vim.uv.sleep(2000)
    --     -- vscode.call('editor.action.reindentselectedlines')
    --     -- vim.cmd.normal(vim.api.nvim_replace_termcodes('<Esc>', true, true, true))
    --     -- vim.cmd.normal(vim.api.nvim_replace_termcodes('<Esc>', true, true, true))
    -- end

    --
    --可视模式下, ==缩进选中的内容. normal模式下, ==缩进当前行
    -- vscode没有提供缩进当前行的api. 因此先按V选中当前行, 再缩进选中行, 再按<Escape>退出选择
    keyset("n", "==", function()
        vim.cmd.normal("V")
        vscode.call("editor.action.reindentselectedlines")
        vim.cmd.normal(vim.api.nvim_replace_termcodes("<Esc>", true, true, true))
    end, { silent = true, remap = false })
    -- 或者
    -- keyset("n", "==", "V<Cmd>lua require('vscode-neovim').call('editor.action.reindentselectedlines')<CR><Esc>",
    -- { silent = true })
    --
    --清除cmdline的输出, 这里不能用 <cmd>整式的映射
    -- keyset("n", "<Esc>", ":echo ''<CR><Esc>", { silent = true, remap = false })
    keyset("n", "<Esc>", ":noh<CR>:echo ''<CR><Esc>", { silent = true, remap = false })

    -- local vim_mappings = vim.fn.stdpath("config") .. "/lua/config/keymaps.vim"
    -- vim.cmd.source(vim_mappings)

    -- 参考 https://github.com/vscode-neovim/vscode-neovim/issues/259 非常奇怪. vim.keymap.set不起作用
    -- vim.keymap.set({"n"}, "j", "gj", {desc = "向下移动" })
    -- vim.keymap.set({"n"}, "k", "gk", {desc = "向下移动" })
    vim.api.nvim_exec2("nmap j gj", { output = false })
    vim.api.nvim_exec2("nmap k gk", { output = false })
    vim.api.nvim_exec2("vmap j gj", { output = false })
    vim.api.nvim_exec2("vmap k gk", { output = false })

    -- undo/REDO via vscode
    -- vscode本身也维护了一份redo undo的历史记录. 但是vscode的undo/redo和neovim的undo/redo是分开的.
    keyset("n", "u", "<Cmd>call VSCodeNotify('undo')<CR>")
    keyset("n", "<C-r>", "<Cmd>call VSCodeNotify('redo')<CR>")
end

if vim.g.vscode then
    vscode_keymap_setup()
else
    keyset({ "n", "v" }, "j", "gj", { noremap = true, desc = "向下移动" })
    keyset({ "n", "v" }, "k", "gk", { noremap = true, desc = "向下移动" })
end
