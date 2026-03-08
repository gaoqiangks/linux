-- 导入工具函数库
local home_dir = utils.home_dir()

-- 从工具库中提取常用函数
local first_n = utils.first_n -- 返回类型：function -> list
local map = utils.map -- 返回类型：function -> list
local remove_prefix = utils.remove_prefix -- 返回类型：function -> string
local filter_path = utils.filter_path -- 返回类型：function -> list

-- 文件项处理函数：将路径转换为snacks dashboard可用的格式
-- 参数item: table {path: string}
-- 返回值: table {file: string, icon: string, action: string, autokey: boolean}
local snacks_dashboard_file_item = function(item)
    return {
        file = item.path, -- 文件路径
        icon = "file", -- 图标类型
        action = ":e " -- 打开文件的操作命令
            .. vim.fn.fnameescape(item.path),
        autokey = true, -- 启用自动快捷键
    }
end

-- 会话项处理函数：将会话信息转换为snacks dashboard可用的格式
-- 参数item: table {path: string, session_file: string}
-- 返回值: table {file: string, icon: string, action: string, autokey: boolean}
local snacks_dashboard_session_item = function(item)
    return {
        file = item.path, -- 会话对应的项目路径
        icon = "directory", -- 图标类型（目录）
        action = [[:lua require('persisted').load(]] -- 加载会话的操作命令
            .. [[{session =]]
            .. [["]]
            .. item.session_file
            .. [["})]],
        autokey = true, -- 启用自动快捷键
    }
end

-- 统一的snacks dashboard项生成器
-- @param type: string - 项类型，"recent_files" 或 "sessions"
-- @param filters: table - 过滤器配置，包含数量限制和路径模式
-- 返回值: function() -> list<table> - 返回一个闭包函数，调用该函数返回处理后的项列表
local get_snack_dashboard_item = function(type, filters)
    local lst = {} -- 原始数据列表：list<{path: string, session_file?: string}>
    local snacks_item = nil -- 对应的项处理函数：function(item) -> table

    if type == "recent_files" then
        snacks_item = snacks_dashboard_file_item -- function -> table
        lst = utils.get_recent_files() -- 返回list<{path: string}>
        -- 确保oldfiles数据已加载
        -- vim.cmd('rshada')
        -- -- 转换vim.v.oldfiles为统一格式
        -- lst = map(vim.v.oldfiles, function(path) -- 返回list<{path: string}>
        --     return { path = path }
        -- end)
    else
        if type == "sessions" then
            snacks_item = snacks_dashboard_session_item -- function -> table
            lst = utils.get_sessions() -- 返回list<{path: string, session_file: string}>
            -- local r = require("persisted")
            -- local paths = {}                            -- list<string> - 会话文件路径列表
            -- if r then
            --     paths = r.list()                        -- 获取所有会话文件路径：list<string>
            -- end
            --
            -- local base_path = utils.home_dir .. "/.local/share/nvim/sessions/"
            -- -- 处理会话路径：移除前缀、转换编码、去除扩展名
            -- lst = map(paths, function(path) -- 返回list<{path: string, session_file: string}>
            --     -- 去掉指定的前缀路径
            --     local stripped_path = path:gsub("^" .. base_path, "")
            --     -- 将URL编码的%转换为路径分隔符/
            --     local final_path = stripped_path:gsub("%%", "/")
            --     -- 移除.vim扩展名，返回处理后的路径和原始会话文件
            --     return { path = final_path:gsub(".vim$", ""), session_file = path }
            -- end)
        end
    end

    -- 应用路径过滤器
    local lst_filtered = filter_path(lst, filters) -- 返回list<{path: string, session_file?: string}>

    -- 返回闭包函数，延迟执行项转换
    -- 返回值: function() -> list<table> - 其中每个table是snacks_item的返回值
    return function()
        return map(lst_filtered, snacks_item) -- 返回list<table>
    end
end

-- 获取最近文件项的便捷函数
-- @param filters: table - 过滤器配置
-- 返回值: function() -> list<table> - 闭包函数，调用返回文件项列表
local get_recent_files = function(filters)
    return get_snack_dashboard_item("recent_files", filters) -- 返回function() -> list<table>
end

-- 获取会话项的便捷函数
-- @param filters: table - 过滤器配置
-- 返回值: function() -> list<table> - 闭包函数，调用返回会话项列表
local get_sessions = function(filters)
    return get_snack_dashboard_item("sessions", filters) -- 返回function() -> list<table>
end

local key_text = function(item)
    return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]  ", hl = "special" } }
end
local dashboard_enabled = true -- 是否启用dashboard功能
local argv = vim.v.argv
for _, v in ipairs(argv) do
    if v == "-c" then
        dashboard_enabled = false -- 如果命令行参数包含"-c"，则禁用dashboard功能
    end
end

vim.api.nvim_create_autocmd("User", {
    pattern = "SnacksDashboardOpened", -- 监听所有 User 自定义事件
    callback = function(ev)
        vim.opt_local.cursorline = true
        -- ev.match 包含了触发的具体事件名，例如 "SnacksDashboardOpened"
        -- print("当前触发的 User 事件是: " .. ev.match)

        -- 如果你想针对性地处理 SnacksDashboard
        -- if ev.match == "SnacksDashboardOpened" then
        --     vim.opt_local.cursorline = true
        --     print("检测到 Dashboard 开启，已激活 cursorline")
        -- end
    end,
})
--
-- 返回snacks.nvim插件配置
-- 返回值: table - 插件配置表
return {
    -- 插件Git仓库地址
    -- url = "git@github.com:gaoqiangks/snacks.nvim.git",
    "folke/snacks.nvim",
    -- 插件配置选项
    opts = {
        dashboard = {
            enabled = dashboard_enabled, -- 是否启用dashboard功能
            width = 90, -- dashboard宽度
            formats = {
                -- 返回值: table - 图标配置表
                icon = function(item)
                    -- log.debug(vim.inspect(item))
                    local M = require("snacks.dashboard")
                    -- 根据文件类型和图标设置返回对应图标
                    if item.file and item.icon == "file" or item.icon == "directory" then
                        local icon = M.icon(item.file, item.icon) -- 返回table
                        local keytext = key_text(item)
                        table.insert(keytext, icon)
                        return keytext
                    end
                    return { item.icon, width = 2, hl = "icon" } -- 返回table
                end,
                key = function(item)
                    return key_text(item) -- 返回list<table>
                end,
                -- 文件路径格式化函数
                -- 参数item: table - snacks项
                -- 参数ctx: table - 上下文信息，包含width等
                -- 返回值: list<table> - 高亮片段列表
                file = function(item, ctx)
                    local fname = vim.fn.fnamemodify(item.file, ":~")
                    -- 移除用户主目录前缀
                    fname = remove_prefix(fname, home_dir)
                    -- 根据上下文宽度调整显示
                    fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname

                    -- 如果路径仍然过长，进行智能截断
                    if #fname > ctx.width then
                        local dir = vim.fn.fnamemodify(fname, ":h")
                        local file = vim.fn.fnamemodify(fname, ":t")
                        if dir and file then
                            -- 保留目录，截断文件名
                            file = file:sub(-(ctx.width - #dir - 2))
                            fname = dir .. "/…" .. file
                        end
                    end

                    -- 分离目录和文件名，以便分别高亮
                    local dir, file = fname:match("^(.*)/(.+)$")
                    -- 返回list<table>，每个table是{text, hl}结构
                    return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
                end,
            },
            sections = {
                -- 会话部分配置
                { title = "Sessions" }, -- 标题项：table
                get_sessions({ -- 返回function() -> list<table>
                    n = 10, -- 最多显示10个会话
                    check_exist = true, -- 检查文件是否存在
                    patterns_included = {
                        "^" .. home_dir, -- 包含用户主目录下的会话
                    },
                    patterns_excluded = {
                        "^" .. home_dir .. "$", -- 包含用户主目录下的会话
                    },
                }), -- snacks.nvim会调用这个函数获取会话项列表
                { padding = 0 }, -- 间距项：table
                -- 最近文件部分配置
                { title = "Recent Files" }, -- 标题项：table
                get_recent_files({ -- 返回function() -> list<table>
                    n = 10, -- 最多显示10个文件
                    check_exist = true, -- 检查文件是否存在
                    patterns_included = {
                        "^" .. home_dir, -- 包含用户主目录下的会话
                    },
                    patterns_excluded = {
                        ".git", -- 排除.git目录
                    },
                }), -- snacks.nvim会调用这个函数获取文件项列表
            },
        },
    },
    -- 插件初始化函数
    init = function() -- 返回nil
        vim.g.snacks_animate = false -- 禁用动画效果
        -- 为特定文件类型设置自动命令
        -- vim.api.nvim_create_autocmd({ "FileType", "BufAdd", "BufEnter", "WinEnter" }, {
        --     callback = function()
        --         ftype = vim.api.nvim_get_option_value("filetype", { scope = "local", buf = 0 })
        --         log.debug("Entered snacks_dashboard, filetype:" .. ftype)
        --         if vim.api.nvim_get_option_value("filetype", { scope = "local", buf = 0 }) == "snacks_dashboard" then
        --             vim.o.cursorline = true
        --         end
        --     end
        -- })
        --
        -- vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
        --     callback = function()
        --         if vim.api.nvim_get_option_value("filetype", { scope = "local", buf = 0 }) == "snacks_dashboard" then
        --             vim.o.cursorline = false
        --         end
        --     end
        -- })
        -- -- 临时添加来查看当前缓冲区的信息
        -- vim.api.nvim_create_autocmd("BufEnter", {
        --     callback = function(args)
        --         local buf = args.buf
        --         log.debug("Buffer name:", vim.api.nvim_buf_get_name(buf))
        --         log.debug("Filetype:", vim.api.nvim_get_option_value("filetype", { scope = "local", buf = 0 }))
        --     end
        -- })
    end,
}
