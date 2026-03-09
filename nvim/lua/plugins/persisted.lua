return {
    "olimorris/persisted.nvim",
    -- enabled = false,
    -- event = "BufReadPre", -- Ensure the plugin loads only when a buffer has been loaded
    lazy = false,
    config = function()
        log.debug("persisted.lua: config 开始")
        local uv = vim.loop
        require("persisted").setup({
            -- should_save = function()
            --     local cwd = vim.fn.getcwd()
            --
            --     -- 检查当前目录是否为空
            --     local scan = uv.fs_scandir(cwd)
            --     local has_file = false
            --     if scan then
            --         for name in function() return uv.fs_scandir_next(scan) end do
            --             has_file = true
            --             break
            --         end
            --     end
            --     if not has_file then return false end
            --
            --     -- 检查是否有修改过的文件属于当前目录
            --     local buffers = vim.fn.getbufinfo({ buflisted = 1 })
            --     for _, buf in ipairs(buffers) do
            --         if buf.name then
            --             local realpath = uv.fs_realpath(buf.name)
            --             if realpath and realpath:find(cwd, 1, true) == 1 then
            --                 return true
            --             end
            --         end
            --     end
            --
            --     return false
            -- end,
            should_save = function() return true end,
            autostart = true,
            autosave = true,
            -- autoload = true,
        })
        local persisted_autostart = vim.api.nvim_create_augroup("persisted_autostart", { clear = true })

        vim.api.nvim_create_autocmd({ "VimEnter" }, {
            group = persisted_autostart,
            pattern = "*",
            callback = function()
                log.debug("persisted.lua: VimEnter 触发，启动 session 管理")
                vim.cmd("Persisted start")
            end,
        })
        require("telescope").load_extension("persisted")
    end
}
