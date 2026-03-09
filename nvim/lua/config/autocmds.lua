vim.cmd.source("~/.config/nvim/lua/config/autocmds.vim")
if vim.g.vscode then
    return
end
log.debug("autocmds.lua: 开始加载")
local fn = vim.fn

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local newcommand = vim.api.nvim_create_user_command

-- 如果在wsl中, 则定义新的命令Explorer, 用于打开windows的explorer
if in_wsl then
    newcommand("Explorer", function()
        local current_file = vim.api.nvim_buf_get_name(0) -- 获取当前 buffer 的文件路径
        local current_dir = "."
        if current_file ~= "" then
            current_dir = vim.fn.fnamemodify(current_file, ":p:h") -- 提取目录部分
        end
        log.debug("autocmds.lua: Explorer 命令执行，current_dir =", current_dir)
        local handle = io.popen("wslpath -w " .. current_dir) -- 调用 wslpath 命令
        local dir = handle:read("*a") -- 读取命令输出
        handle:close() -- 关闭句柄

        dir = dir:gsub("%s+", "") -- 去除路径末尾的换行符或空格
        dir = dir:gsub("\\", "\\\\")
        local cmd = "explorer.exe " .. '"' .. dir .. '"'
        -- log("cmd = " .. cmd)
        vim.fn.system(cmd)
    end, { desc = "Open Windows Explorer" })
end

-- 将macos的plist文件设置为xml文件类型
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.plist",
    callback = function()
        log.debug("autocmds.lua: plist 文件，设置 filetype = xml")
        vim.bo.filetype = "xml"
    end,
})

-- 只有在插入模式和搜索模式下才启用输入法, 这样在normal模式下即使仍然是中文输入法, 也不会影响normal command的执行
local function disable_IME_when_normal()
    local set_ime = function(args)
        if args.event:match("Enter$") then
            vim.g.neovide_input_ime = true
        else
            vim.g.neovide_input_ime = false
        end
        log.debug("autocmds.lua: IME 状态变化，event =", args.event, "ime =", tostring(vim.g.neovide_input_ime))
    end

    local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })

    vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
        group = ime_input,
        pattern = "*",
        callback = set_ime,
    })

    vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
        group = ime_input,
        pattern = "[/\\?]",
        callback = set_ime,
    })
end
log.debug("autocmds.lua: neovide =", tostring(vim.g.neovide ~= nil))
if vim.g.neovide then
    disable_IME_when_normal()
end

--- 自动命令组：处理 .tex 文件保存时的空行注释
--- 但是vscode-neovim没有BufWritePre事件
-- vim.api.nvim_create_autocmd("BufWritePre", {
--     pattern = "*",
--     callback = function()
--         if vim.bo.filetype ~= "tex" then
--             return
--         end
--         local bufnr = vim.api.nvim_get_current_buf()
--         local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--         local changed = false
--         for i, line in ipairs(lines) do
--             if line:match("^%s*$") then
--                 lines[i] = "% " .. line
--                 changed = true
--             end
--         end
--         if changed then
--             vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
--         end
--         -- log(".tex file: empty lines are commented out")
--     end,
-- })
