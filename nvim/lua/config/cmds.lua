log.debug("cmds.lua: 开始加载自定义命令")
vim.api.nvim_create_user_command("CopyAll", function()
    log.debug("cmds.lua: CopyAll 命令执行")
    utils.copy_entire_file()
    print("File content copied to clipboard")
end, { desc = "Copy entire file to clipboard" })

-- 清空当前 buffer 但不覆盖寄存器内容
vim.api.nvim_create_user_command("BufClear", function()
    log.debug("cmds.lua: BufClear 命令执行")
    -- 使用黑洞寄存器删除所有内容，不影响任何寄存器
    vim.cmd("%delete _")
end, { desc = "清空当前 buffer，不覆盖寄存器" })
