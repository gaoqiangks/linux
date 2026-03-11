require("lib.string")

-- ========== 日志系统模块 ==========
local log_module = {}

-- 日志配置
log_module.config = {
    enabled = true, -- 全局总开关，默认关闭
    level = "DEBUG", -- 默认日志级别
    levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 },
}

-- 获取日志目录和文件名
log_module.get_log_path = function()
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    local log_dir = home .. "/.nvim_logs"

    -- 创建日志目录（如果不存在）
    local uv = vim.loop
    if not uv.fs_stat(log_dir) then
        uv.fs_mkdir(log_dir, 493) -- 0755 权限
    end

    -- 生成带时间戳的文件名
    local timestamp = os.date("%Y-%m-%d")
    return log_dir .. "/nvim_" .. timestamp .. ".log"
end

-- 核心日志函数
log_module.write = function(level, message, ...)
    -- 检查开关和级别
    if not log_module.config.enabled then
        return
    end

    local msg_level_num = log_module.config.levels[level]
    local conf_level_num = log_module.config.levels[log_module.config.level]
    if not msg_level_num or msg_level_num < conf_level_num then
        return
    end

    -- 格式化消息
    local formatted_msg
    if select("#", ...) > 0 then
        -- formatted_msg = string.format(message, ...)
        -- 将message和额外参数用空格连接起来
        local args = { ... }
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        formatted_msg = tostring(message) .. " " .. table.concat(args, " ")
    else
        formatted_msg = tostring(message)
    end

    -- 获取调用信息
    local caller_info = debug.getinfo(3, "Sl")
    local caller = caller_info and string.format("%s:%s", caller_info.short_src, caller_info.currentline) or "?:?"

    -- 构建日志行
    local log_line = string.format("[%s] [%s] %s - %s\n", os.date("%H:%M:%S"), level, caller, formatted_msg)

    -- 写入文件
    local log_path = log_module.get_log_path()
    local file, err = io.open(log_path, "a")
    if file then
        file:write(log_line)
        file:close()
    else
        -- 写入失败时在控制台显示（仅限调试）
        if log_module.config.level == "DEBUG" then
            vim.notify("日志写入失败: " .. tostring(err), vim.log.levels.WARN)
        end
    end
end

-- 便捷日志函数
log_module.debug = function(message, ...)
    log_module.write("DEBUG", message, ...)
end

log_module.info = function(message, ...)
    log_module.write("INFO", message, ...)
end

log_module.warn = function(message, ...)
    log_module.write("WARN", message, ...)
end

log_module.error = function(message, ...)
    log_module.write("ERROR", message, ...)
end

-- 日志控制函数
log_module.enable = function()
    log_module.config.enabled = true
    log_module.info("====== 日志系统已启用 ======")
end

log_module.disable = function()
    log_module.info("====== 日志系统已关闭 ======")
    log_module.config.enabled = false
end

log_module.set_level = function(level)
    if log_module.config.levels[level] then
        local old_level = log_module.config.level
        log_module.config.level = level
        log_module.info("日志级别从 %s 变更为 %s", old_level, level)
    else
        log_module.error("无效的日志级别: %s", tostring(level))
    end
end

-- 导出日志模块
local log = log_module

local function get_os()
    -- 安全执行命令
    local function safe_read(cmd)
        local ok, result = pcall(function()
            local f = io.popen(cmd)
            if not f then
                return nil
            end
            local output = f:read("*l")
            f:close()
            return output
        end)
        return ok and result or nil
    end

    -- 检查 WSL
    local function is_wsl()
        local ok, content = pcall(function()
            local f = io.open("/proc/version", "r")
            if not f then
                return nil
            end
            local data = f:read("*a")
            f:close()
            return data
        end)
        return ok and content and content:lower():find("microsoft") ~= nil
    end

    -- 主逻辑
    local uname = safe_read("uname -s")
    uname = uname and uname:lower() or ""

    local result
    if uname:find("darwin") then
        result = "macos"
    elseif uname:find("linux") then
        result = is_wsl() and "wsl" or "linux"
    elseif uname:find("windows") then
        result = "windows"
    else
        -- fallback: 动态库扩展名推断
        local ext = package.cpath:match("%p[\\/]?%p(%a+)")
        if ext == "dll" then
            result = "windows"
        elseif ext == "so" then
            result = "linux"
        elseif ext == "dylib" then
            result = "macos"
        else
            result = "unknown"
        end
    end

    return result
end

local function in_wsl()
    return get_os() == "wsl"
end

local function in_macos()
    return get_os() == "macos"
end

local function in_linux()
    return get_os() == "linux"
end

local paste_yanked_select = function(arg)
    if arg == "above" then
        vim.api.nvim_exec2(vim.api.nvim_replace_termcodes("normal O<Esc>P", true, false, true), { output = false })
    else
        vim.api.nvim_exec2(vim.api.nvim_replace_termcodes("normal o<Esc>p", true, false, true), { output = false })
    end
    --选中刚刚粘贴的内容
    vim.cmd.normal("`[v`]")
end
local indent_selected_lines = function()
    if vim.g.vscode then
        vscode.call("editor.action.reindentselectedlines")
    else
        vim.cmd.normal("==")
    end
end
local paste_and_indent = function(arg)
    indent.paste_yanked_select(arg)
    indent.indent_selected_lines()
end

local get_hl = function(name)
    local ok, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)
    if not ok then
        return nil
    end
    hl_test = hl
    for _, key in pairs({ "foreground", "background", "special" }) do
        if hl[key] then
            hl[key] = string.format("#%06x", hl[key])
        end
    end
    return hl
end

local get_iterm_id = function()
    if (not vim) or (vim.env.TERM_PROGRAM ~= "iTerm.app") or vim.g.neovide then
        -- log("not in nvim or not iTerm2")
        return { nil, nil }
    end
    local pycode = [[
import iterm2

async def main(connection):
    app = await iterm2.async_get_app(connection)
    for window in app.windows:
        for tab in window.tabs:
            for session in tab.sessions:
                print(f"{session.name}----{session.session_id}----{tab.tab_id}----{window.window_id}")
iterm2.run_until_complete(main)
]]

    local sessions = vim.fn.system({ "python3", "-c", 'exec("""' .. pycode .. '""")' })
    -- print(sessions)

    local parsed = {}

    function split(str, sep)
        local result = {}
        local start = 1
        local sep_start, sep_end = string.find(str, sep, start, true)

        while sep_start do
            table.insert(result, string.sub(str, start, sep_start - 1))
            start = sep_end + 1
            sep_start, sep_end = string.find(str, sep, start, true)
        end

        -- 插入最后一个字段
        table.insert(result, string.sub(str, start))
        return result
    end

    for line in sessions:gmatch("[^\r\n]+") do
        -- 去除前后空白
        local trimmed = line:match("^%s*(.-)%s*$")

        -- 跳过空白行
        if trimmed ~= "" then
            local fields = split(trimmed, "----")
            if #fields == 4 then
                table.insert(parsed, fields)
            else
                print("⚠️ 跳过格式错误的行: " .. trimmed)
            end
        end
    end

    local target_sid = vim.env.ITERM_SESSION_ID or "0"
    if target_sid ~= "0" then
        local sep_start = string.find(target_sid, ":", 1, true)

        if sep_start then
            target_sid = string.sub(target_sid, sep_start + 1)
        end
    end

    local window_id = nil
    local tab_id = nil
    -- 打印结果
    for i, row in ipairs(parsed) do
        -- local found = false
        -- print(string.format("Line %d:", i))
        for j, value in ipairs(row) do
            -- print(string.format("  Field %d: %s", j, value))
            if target_sid == value then
                window_id = row[4]
                tab_id = row[3]
                -- print("找到目标会话ID: " .. target_sid .. "  窗口ID: " .. row[4])
                goto done
            end
        end
    end
    ::done::
    return { tab_id, window_id }
end

-- 返回当前 iTerm2 session 的 UUID（ITERM_SESSION_ID 中 ":" 之后的部分）
local get_iterm_session_id = function()
    if (not vim) or (vim.env.TERM_PROGRAM ~= "iTerm.app") or vim.g.neovide then
        return nil
    end
    local sid = vim.env.ITERM_SESSION_ID or ""
    if sid == "" then
        return nil
    end
    local sep = string.find(sid, ":", 1, true)
    if sep then
        return string.sub(sid, sep + 1)
    end
    return sid
end

local environments_list = {
    "align",
    "aligned",
    "bmatrix",
    "cases",
    "claim",
    "conditions",
    "corollary",
    "definition",
    "enumerate",
    "equation",
    "example",
    "exercise",
    "figure",
    "itemize",
    "lemma",
    "pmatrix",
    "problem",
    "proof",
    "proposition",
    "question",
    "remark",
    "solution",
    "split",
    "subproof",
    "theorem",
    "vmatrix",
    "flatenum",
}

local modify_string = function(input_string, add_char)
    local modified_string = ""
    for i = 1, #input_string do
        local char = input_string:sub(i, i)
        if i >= 3 then
            modified_string = modified_string .. char .. add_char
        else
            modified_string = modified_string .. char
        end
    end
    return modified_string
end

local env_regex_keys = function()
    local env_keys = {}
    for _, env in ipairs(environments_list) do
        local env_key = { modify_string(env, "?") }
        -- local env_key = {modify_string(env, "")}
        env_keys[env] = env_key
    end
    table.insert(env_keys["split"], "\\ss")
    return env_keys
end

local env_normal_keys = function()
    local env_keys = {}
    for _, env in ipairs(environments_list) do
        local env_key = { env }
        env_keys[env] = env_key
    end
    table.insert(env_keys["split"], "ss")
    return env_keys
end

local generate_snippets_vscode = function()
    local idx = 0
    local total_envs = 0
    local env_keys = env_normal_keys()
    for _, keys in pairs(env_keys) do
        for _, _ in ipairs(keys) do
            total_envs = total_envs + 1
        end
    end
    print("{")
    for _, keys in pairs(env_keys) do
        for _, env_name in ipairs(keys) do
            print("")
            print("")
            print("", '"' .. env_name .. '":{')
            print("", '\t"prefix":' .. '"' .. env_name .. '",')
            print("", "\t" .. '"body":[')
            print("", '\t\t"\\\\begin{' .. env_name .. '}",')
            print("", '\t\t"\\t$1",')
            print("", '\t\t"\\\\end{' .. env_name .. '}"')
            print("", "\t],")
            print("", [["luasnip" : {"priority": 6000}]])
            print("", "},")
        end
    end

    for _, keys in pairs(env_keys) do
        for _, env_name in ipairs(keys) do
            idx = idx + 1
            print("")
            print("")
            print("", '"' .. env_name .. '*":{')
            print("", '\t"prefix":' .. '"*' .. env_name .. '",')
            print("", "\t" .. '"body":[')
            print("", '\t\t"\\\\begin{' .. env_name .. '*}",')
            print("", '\t\t"\\t$1",')
            print("", '\t\t"\\\\end{' .. env_name .. '*}"')
            print("", "\t],")
            print("", "", [["luasnip" : {"priority": 4000}]])
            print("", "},")
        end
    end
    print([[        "begin{}":{
        "prefix":"begin",
        "body":[
        "\\begin{${1:name}}",
        "\t$2",
        "\\end{${1:name}}"
        ],
        "luasnip": {"priority": 6000}
    }
    ]])

    print("}")
end

local generate_snippets_ultisnips = function()
    print("priority 99")
    local env_keys = env_regex_keys()
    for env, keys in pairs(env_keys) do
        for _, key in ipairs(keys) do
            local snippet = {
                trigger = key,
                description = '"' .. env .. '"',
                body = {
                    "\\begin{" .. env .. "}",
                    "\t$0",
                    "\\end{" .. env .. "}",
                },
            }
            print("snippet", '"' .. snippet.trigger .. '"', snippet.description, "br")
            print(snippet.body[1])
            print(snippet.body[2])
            print(snippet.body[3])
            print("endsnippet")
            print("")
            snippet.body = {
                "\\begin{" .. env .. "*}",
                "\t$0",
                "\\end{" .. env .. "*}",
            }
            print("snippet", '"\\*' .. snippet.trigger .. '"', snippet.description, "br")
            print(snippet.body[1])
            print(snippet.body[2])
            print(snippet.body[3])
            print("endsnippet")
            print("")
        end
    end
end

local generate_snippets = function(type)
    if type == "vscode" then
        generate_snippets_vscode()
    elseif type == "ultisnips" then
        generate_snippets_ultisnips()
    else
        print("")
    end
end

local str2table = function(str)
    local t = {}
    str:gsub(".", function(c)
        table.insert(t, c)
    end)
    return t
end

-- 模糊查找env
local get_env = function(arg)
    if not arg then
        return ""
    end
    --有时候不小心将equation输成\equation, 所以先去掉"\"
    local env_short = arg:gsub("\\", "")
    --如果arg是空字符串, 比如取消了操作, 则返回空字符串
    if env_short == "" then
        return ""
    end
    -- -与*的作用类似, 只是-是匹配最短的, *是匹配最长的
    env_short, idx = env_short:gsub("^%s*(.-)%s*$", "%1")
    -- 第一个字符串
    local first_c = env_short:sub(1, 1)
    -- 是否以*开头
    local stared = false
    if first_c == "*" then
        env_short = env_short:sub(2)
        stared = true
    end
    -- 是否以*结尾
    local last_c = env_short:sub(-1)
    if last_c == "*" then
        env_short = env_short:sub(1, -2)
        -- print("env_short", env_short)
        stared = true
    end
    -- print(first_c, last_c, env_short, stared)
    -- print("last_c", last_c)
    -- print("env_short", env_short)
    -- print("stared", stared)

    local final_env = ""
    --输入split, 返回split
    -- 比如输入ss, 就会返回split
    local environments_dict = {
        ss = "split",
    }
    local environments = {}
    -- ipairs用于数组  pairs用于词典
    for _, env in ipairs(environments_list) do
        environments[env] = env
    end
    for k, env in pairs(environments_dict) do
        environments[k] = env
    end
    local substr_matched = {}
    local regex_matched = {}
    for env, _ in pairs(environments) do
        startindex, endindex = string.find(env, env_short)
        if startindex and startindex == 1 then
            table.insert(substr_matched, env)
        end
    end
    for env, _ in pairs(environments) do
        --先按substring匹配查找
        -- print("env= "..env)
        if string.find(env, env_short) then
            table.insert(substr_matched, env)
        end
    end
    if #substr_matched >= 1 then
        -- 首先是按substring查找, 如果找到了就结束. 可能有很多个都符合substring匹配的, 只需要简单返回第一个即可. 因为此时也无法判断到底哪个更合适
        final_env = substr_matched[1]
    else
        local strt = str2table(env_short)
        local regexs = ""
        for _, c in ipairs(strt) do
            regexs = regexs .. ".*" .. c
        end
        regexs = "^" .. regexs
        --将字符串equation转成正则表达式^.*e.*q.*u.*a.*t.*i.*o.*n
        for env, _ in pairs(environments) do
            local init_p, end_p = string.find(env, regexs)
            --正则匹配也要求至少第一个字母相同
            if init_p == 1 then
                table.insert(regex_matched, env)
            end
        end
        if #regex_matched == 0 then
            final_env = env_short
        else
            final_env = regex_matched[1]
        end
    end
    -- print("final_env= ".. final_env)
    final_env = environments[final_env]
    if not final_env then
        final_env = arg
    end
    -- 如果是以*开头或者结尾的, 则加上*
    if stared then
        final_env = final_env .. "*"
    end
    return final_env
end

-- local map = {}
--
-- function map.register(action)
--     action.options.desc = action.description
--     vim.keymap.set(action.mode, action.lhs, action.rhs, action.options)
-- end
--
-- function map.unregister(mode, lhs, opts)
--     vim.keymap.del(mode, lhs, opts)
-- end
--
-- function map.bulk_register(actions)
--     for _, action in pairs(actions) do
--         map.register(action)
--     end
-- end
local map = function(tbl, func)
    local new_tbl = {} -- 新表，用于存储结果
    for k, v in pairs(tbl) do
        new_tbl[k] = func(v)
    end
    return new_tbl
end

-- map_filter接收两个函数, 一个表tbl, 一个过虑函数func. 只有当func返回true时, 才会将tbl中的元素添加到新表中
-- 这个函数的作用是对表中的每个元素应用func函数, 并返回一个新表, 其中包含所有func返回true的元素
local map_filter = function(tbl, func)
    local new_tbl = {} -- 新表，用于存储结果
    for _, v in ipairs(tbl) do
        if func(v) then
            new_tbl[#new_tbl + 1] = v
        end
    end
    return new_tbl
end

local function remove_prefix(path, prefix)
    -- 检查路径是否以指定的前缀开头
    if path:sub(1, #prefix) == prefix then
        -- 移除前缀并返回剩余路径
        return path:sub(#prefix + 1)
    else
        -- 如果路径没有指定前缀，直接返回原路径
        return path
    end
end

local function file_exists(path)
    return vim.loop.fs_stat(path) ~= nil
end

local function first_n(array, n)
    if not n or n < 0 then
        n = #array
    end
    local new_array = {}
    for i = 1, math.min(n, #array) do
        table.insert(new_array, array[i])
    end
    return new_array
end

-- 参数格式
-- paths= {
-- {path = xxx},
-- {path = xxx},
-- }
--
-- filters = {
-- patterns = { {pattern = pattern, match = false}},
-- 如果match = false, 说明要从结果中排除这个路径
-- 如果match = true, 说明要从结果中找出匹配这个路径的
--
-- 排除路径的优先级大于包含路径
-- n = -1,
-- shorten = false,
-- }
local filter_path = function(paths, filters)
    local uv = vim.loop -- 使用 Neovim 的文件系统模块
    -- 初始化 filters，确保 path 和 pattern 存在
    filters = filters or { patterns = {}, shorten = false, n = -1, exclude_system = true }
    paths = paths or {}
    local filters_excluded = filters.patterns_excluded or {}
    local filters_included = filters.patterns_included or {}
    -- for _, item in pairs(filters.patterns or {}) do
    --     if item.match then
    --         table.insert(filters_included, item.pattern)
    --     else
    --         table.insert(filters_excluded, item.pattern)
    --     end
    -- end

    --首先把匹配了patterns_included的路径找出来
    --然后再检查该路径是否存在
    --然后再排除patterns_excluded的路径
    local paths_patterns_done = {}
    for _, item in ipairs(paths) do
        for _, pattern in ipairs(filters_included) do
            if item.path:match(pattern) then
                table.insert(paths_patterns_done, item)
                break
            end
        end
    end

    local paths_patterns_done_exist = paths_patterns_done
    if filters.check_exist then
        paths_patterns_done_exist = map_filter(paths_patterns_done, function(item)
            return file_exists(item.path)
        end)
    end

    local paths_done = map_filter(paths_patterns_done_exist, function(item)
        -- 排除系统目录
        for _, pattern in ipairs(filters_excluded) do
            if item.path:match(pattern) then
                return false
            end
        end
        return true
    end)
    -- for i, item in ipairs(paths_patterns_done_exist) do
    --     for _, pattern in ipairs(filters_excluded) do
    --         if item.path:match(pattern) then
    --             table.remove(paths_done, i)
    --         end
    --     end
    -- end
    return first_n(paths_done, filters.n)
end

local function shorten_path(path)
    -- 将home目录替换为~，并按fish shell的方法截短路径
    local home = vim.fn.expand("~")
    if path:sub(1, #home) == home then
        path = "~" .. path:sub(#home + 1)
    end

    -- 使用 UTF-8 安全的方法分割路径
    local parts = vim.split(path, "/", { plain = true })
    for i = 1, #parts - 1 do
        if parts[i] ~= "~" then
            -- 使用 `vim.fn.strcharpart` 获取第一个字符（支持多字节字符）
            parts[i] = vim.fn.strcharpart(parts[i], 0, 1)
        end
    end
    return table.concat(parts, "/")
end

local function strip_windows_paths(path)
    local parts = vim.split(path, ":", { plain = true })
    local keep = {}

    for _, p in ipairs(parts) do
        -- 保留 /usr/lib/wsl/lib
        if p == "/usr/lib/wsl/lib" then
            table.insert(keep, p)

            -- 丢弃 /mnt/c/... /mnt/d/... 等 Windows 路径
        elseif p:match("^/mnt/%a/") then
            -- skip
        else
            table.insert(keep, p)
        end
    end

    return table.concat(keep, ":")
end

-- 示例调用
-- print("当前操作系统是: " .. get_os())
-- local get_os = function()
--     local uname = vim.loop.os_uname()
--     local sysname = uname.sysname
--     local is_wsl = vim.fn.has("wsl") == 1
--
--     local system
--     if is_wsl then
--         system = "WSL"
--     elseif sysname == "Darwin" then
--         system = "macOS"
--     elseif sysname == "Linux" then
--         system = "Linux"
--     elseif sysname:match("Windows") or vim.fn.has("win32") == 1 then
--         system = "Windows"
--     else
--         system = "Unknown"
--     end
--     return system
-- end

-- 获取windows terminal的pid, 用于inverse search
local get_wt_pid = function()
    if not vim then
        return nil
    end
    if not in_wsl() then
        return nil
    end
    local winterm_pid = nil
    winterm_pid = os.getenv("WT_PPID")
    if winterm_pid and winterm_pid ~= "" then
        -- log("get_winterm_pid from env:", winterm_pid)
        return winterm_pid
    end

    -- 通过下面的方式启动的WSL, 可以将windows terminal的pid放在环境亦是WT_PPID中
    -- powershell.exe -NoProfile -Command "$env:WT_PID = $PID; $ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId;  $env:WT_PPID = $ppid;  $env:WSLENV = 'WT_PID:WT_PPID'; wsl.exe -d Debian"

    local current_dir = vim.loop.cwd()
    local home_dir = home_dir()
    vim.loop.chdir(home_dir)
    -- 非常奇怪的问题. 在/mnt/c/Users/gaoqiang中执行python.exe /mnt/c/Users/gaoqiang/a.py的话, 路径会被解析为C:\\home\\gaoqiang\\xxx. 而在linux分区下就不会
    -- vim.system是异步执行的, 如果把结果放在一个局部变量中, 当命令执行完时, 局部变量已经不存在了. 所以只能把结果放在一个全局变量中
    -- 新增接口 vim.system():wait() 可以同步等待结果返回
    local result = vim.system({
        -- "/mnt/c/Users/gaoqiang/AppData/Local/Programs/Python/Python313/python.exe",
        "/mnt/c/Users/gaoqiang/OneDrive/programs/python/python_portable/python.exe",
        "/home/gaoqiang/linux/scripts/get_windows_terminal_pid.py",
    }, { text = true }):wait()
    vim.loop.chdir(current_dir)
    winterm_pid = result.stdout:gsub("%s+", "")
    return winterm_pid
end

local function highlight_and_fadeout(arg, highlight_time)
    local startl = arg.startl
    local endl = arg.endl
    local ns_id = arg.ns_id or 1

    -- 更平滑的渐变颜色数组
    local fade_colors = {
        "#555555",
        "#535353",
        "#515151",
        "#4f4f4f",
        "#4d4d4d",
        "#4b4b4b",
        "#494949",
        "#474747",
        "#454545",
        "#434343",
        "#414141",
        "#3f3f3f",
        "#3d3d3d",
        "#3b3b3b",
        "#393939",
        "#373737",
        "#353535",
        "#333333",
        "#313131",
        "#2f2f2f",
        "#2d2d2d",
        "#2b2b2b",
        "#292929",
        "#272727",
        "#252525",
        "#232323",
        "#212121",
        "#1f1f1f",
        "#1d1d1d",
        "#1b1b1b",
        "#191919",
        "#171717",
        "#151515",
        "#131313",
        "#111111",
        "#0f0f0f",
        "#0d0d0d",
        "#0b0b0b",
        "#090909",
        "#070707",
        "#050505",
        "#030303",
        "NONE",
    }

    local delay = 25 -- 每个颜色的过渡时间
    local total_fade_time = #fade_colors * delay -- 总淡出时间

    -- 先清除可能存在的旧高亮
    vim.api.nvim_buf_clear_namespace(0, ns_id, startl - 1, endl)

    -- 设置初始高亮颜色
    vim.cmd("highlight BackSearchHL guibg=" .. fade_colors[1])

    -- 应用初始高亮
    vim.hl.range(0, ns_id, "BackSearchHL", { startl - 1, 0 }, { endl, 0 }, {})

    -- 计算开始淡出的时间点
    local fade_start_time = highlight_time

    -- 使用闭包管理动画状态
    local function start_fade_animation()
        local step = 1

        local function next_color()
            if step <= #fade_colors then
                vim.cmd("highlight BackSearchHL guibg=" .. fade_colors[step])

                -- 清除旧高亮并重新应用新颜色
                vim.api.nvim_buf_clear_namespace(0, ns_id, startl - 1, endl)
                if fade_colors[step] ~= "NONE" then
                    vim.hl.range(0, ns_id, "BackSearchHL", { startl - 1, 0 }, { endl, 0 }, {})
                end

                step = step + 1
                if step <= #fade_colors then
                    vim.defer_fn(next_color, delay)
                else
                    -- 动画结束后清理
                    vim.api.nvim_buf_clear_namespace(0, ns_id, startl - 1, endl)
                    vim.cmd("highlight clear BackSearchHL")
                end
            end
        end

        -- 启动淡出动画
        vim.defer_fn(next_color, delay)
    end

    -- 在指定时间后开始淡出动画
    vim.defer_fn(start_fade_animation, fade_start_time)
end

-- 使用示例
-- highlight_and_fadeout({ startl = 10, endl = 15, ns_id = 1 }, 2000) -- 高亮2秒后开始淡出

local focus_iterm_by_session_id = function(id)
    -- 激活iTerm2的session, 但是这个session是在iTerm2进程中的, 这个命令并没有把iTerm2窗口激活到前台
    vim.fn.system({
        "it2api",
        "activate",
        "session",
        tostring(id),
    })
    -- 把iterm2窗口激活到前台
    vim.fn.system({
        "it2api",
        "activate-app",
    })
end

local focus_iterm = function(iterm_tid, iterm_wid)
    if (not iterm_tid) or not iterm_wid then
        vim.notify("iTerm2 tab ID or window ID not found. Cannot focus iTerm2.", vim.log.levels.WARN)
        return
    end
    -- 首先切换到neovim所在的tab
    vim.fn.system({
        "it2api",
        "activate",
        "tab",
        iterm_tid,
    })
    -- 激活iTerm2的窗口, 但是这个窗口是在iterm2进程中的(iterm2可能会打开很多个窗口, 只有一个窗口是活动窗口), 这个命令并没有把iterm2窗口激活到前台
    vim.fn.system({
        "it2api",
        "activate",
        "window",
        iterm_wid,
    })
    -- 将iTerm2窗口激活到前台
    vim.fn.system({
        "it2api",
        "activate-app",
    })
end

-- inverse search的时候激活vim所成的windows terminal窗口
local activate_windows_terminal = function()
    log.debug(" activate_windows_terminal called")
    if not wt_pid then
        wt_pid = get_wt_pid()
    end
    -- cmd =
    --     [["/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" "C:\Users\gaoqiang\OneDrive\programs\autohotkey\active_terminal_inverse_search.ahk" ]]
    --     .. wt_pid
    --     .. " "
    --     .. vim.fn.expand("%:t")
    cmdlist = {
        "/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe",
        "C:/Users/gaoqiang/OneDrive/programs/autohotkey/active_terminal_inverse_search.ahk",
        wt_pid,
        vim.fn.expand("%:t"),
    }
    -- os.execute(cmd)
    -- 使用os.system会打印一个警告  tcgetpgrp failed: Not a tty
    -- log("cmd = ", cmd)
    -- vim.fn.system(cmd)
    -- log.debug("cmdlist = " .. vim.inspect(cmdlist))
    vim.system(cmdlist):wait()
end

--- 智能检测 Neovide 的 PID（仅 macOS）
local get_neovide_pid = function()
    -- 获取当前 Neovim 的 PID
    local pid = vim.fn.getpid()
    while true do
        -- 获取父进程 PID
        local ppid_handle = io.popen("ps -o ppid= -p " .. pid)
        if not ppid_handle then
            return nil
        end

        local ppid_output = ppid_handle:read("*a")
        ppid_handle:close()

        local ppid = tonumber(ppid_output:match("%d+"))
        if not ppid or ppid <= 1 then
            return nil
        end

        -- 获取父进程名称
        local name_handle = io.popen("ps -p " .. ppid .. " -o comm=")
        if not name_handle then
            return nil
        end

        local pname = name_handle:read("*a")
        name_handle:close()

        pname = pname and pname:match("[^\n]+") or ""

        -- 判断是否为 Neovide
        if pname:lower():find("neovide") then
            -- vim.g.neovide_pid = ppid
            return ppid
        else
            pid = ppid
        end
    end
end
local home_dir = function()
    return os.getenv("HOME")
end

local path = {}

local path_compare = function(path1, path2)
    local uv = vim.loop

    path1 = uv.fs_realpath(path1)
    path2 = uv.fs_realpath(path2)

    if path1 and path2 and path1 == path2 then
        return true
    else
        return false
    end
end

-- 定义一个函数：获取 Visual 模式选中内容并搜索
local search_visual_selection = function()
    -- 获取选中范围
    local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))

    -- Neovim 的行列是 1-based，这里读取选中文本
    local lines = vim.fn.getline(csrow, cerow)
    if #lines == 0 then
        return
    end

    -- 如果是单行，截取列范围
    lines[#lines] = string.sub(lines[#lines], 1, cecol)
    lines[1] = string.sub(lines[1], cscol)

    -- 合并成单行搜索模式
    local text = table.concat(lines, "\n")

    -- 转义正则特殊字符
    text = vim.fn.escape(text, "\\/.*$^~[]")
    -- text = vim.fn.escape(text, [[\/.*$^~[]]])

    -- 设置搜索模式并执行搜索
    vim.fn.setreg("/", text)
    vim.api.nvim_feedkeys("n", "n", false)
end

-- 比较两个路径是否相同, 解析了符号链接及~/之后
path.path_compare = path_compare

-- 复制整个文件到剪贴板
local copy_entire_file = function()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    -- 获取内容
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
    local content = table.concat(lines, "\n")

    -- 设置寄存器
    vim.fn.setreg('"', content)
    vim.fn.setreg("0", content)

    -- 系统剪贴板
    if vim.fn.has("clipboard") == 1 then
        vim.fn.setreg("+", content)
    end

    -- 恢复光标
    vim.api.nvim_win_set_cursor(0, cursor_pos)

    -- 返回信息
    return {
        lines = #lines,
        chars = #content,
        content = content,
    }
end

local function has_env(name)
    return vim.env[name] ~= nil and vim.env[name] ~= ""
end

local function is_wsl()
    return vim.fn.has("wsl") == 1 or has_env("WSL_DISTRO_NAME")
end

local function is_windows()
    return vim.loop.os_uname().sysname == "Windows_NT"
end

local get_nvim_frontend = function()
    -- neovide
    if vim.g.neovide then
        return "neovide"
    end

    -- vscode
    if vim.g.vscode then
        return "vscode"
    end

    -- Windows Terminal
    if has_env("WT_SESSION") then
        if is_wsl() then
            return "wt_wsl"
        elseif is_windows() then
            return "wt_win"
        else
            return "wt"
        end
    end

    -- iTerm2
    if (has_env("TERM_PROGRAM") and vim.env["TERM_PROGRAM"] == "iTerm.app") or has_env("ITERM_SESSION_ID") then
        return "iterm2"
    end

    return "unknown"
end

local get_sessions = function()
    local ok, r = pcall(require, "persisted")
    local paths = {} -- list<string> - 会话文件路径列表
    if ok then
        paths = r.list() -- 获取所有会话文件路径：list<string>
    end

    local base_path = utils.home_dir() .. "/.local/share/nvim/sessions/"
    -- 处理会话路径：移除前缀、转换编码、去除扩展名
    local lst = map(paths, function(path) -- 返回list<{path: string, session_file: string}>
        -- 去掉指定的前缀路径
        local stripped_path = path:gsub("^" .. base_path, "")
        -- 将URL编码的%转换为路径分隔符/
        local final_path = stripped_path:gsub("%%", "/")
        -- 移除.vim扩展名，返回处理后的路径和原始会话文件
        return { path = final_path:gsub(".vim$", ""), session_file = path }
    end)
    return lst
end

local get_recent_files = function()
    vim.cmd("rshada")
    -- 转换vim.v.oldfiles为统一格式
    local lst = map(vim.v.oldfiles, function(path) -- 返回list<{path: string}>
        return { path = path }
    end)
    return lst
end

local is_temporary_buffer = function()
    -- 1. 获取当前 buffer 的属性
    local bufnr = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[bufnr].buftype
    local filetype = vim.bo[bufnr].filetype
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    -- 检查是否为 crontab -e 打开的文件（不视为临时 buffer）
    -- crontab -e 会创建类似 /tmp/crontab.XXXXXX 的文件
    if bufname:match("^/tmp/crontab%.") then
        return false
    end

    -- 2. 检查特殊的 buftype
    -- 'nofile': 内存 buffer，不对应磁盘文件 (常见于插件面板)
    -- 'prompt': 输入框 (如 Telescope)
    -- 'help': 帮助文档
    -- 'quickfix': 快速修复窗口
    local temp_buftypes = {
        nofile = true,
        prompt = true,
        help = true,
        quickfix = true,
        terminal = true,
    }
    if temp_buftypes[buftype] then
        return true
    end

    -- 3. 检查常见临时文件的 filetype
    local temp_filetypes = {
        ["gitcommit"] = true,
        ["gitrebase"] = true,
        ["TelescopePrompt"] = true,
        ["NvimTree"] = true,
        ["notify"] = true,
    }
    if temp_filetypes[filetype] then
        return true
    end

    -- 4. 检查文件路径 (针对系统的 /tmp 目录)
    -- 这里通过检查路径是否包含系统的临时文件夹来判断
    local tmp_dir = os.getenv("TMPDIR") or os.getenv("TMP") or os.getenv("TEMP") or "/tmp"
    if bufname:find(tmp_dir, 1, true) then
        return true
    end

    -- 如果以上都不满足，则认为是一个常规持久化文件
    return false
end

local get_onedrive_root = function()
    -- WSL: 通过 Windows 环境变量 %OneDrive% 获取路径，再用 wslpath 转换
    if in_wsl() then
        local candidates = {
            "/mnt/c/Users/gaoqiang/OneDrive",
            home_dir() .. "/OneDrive",
        }
        for _, p in ipairs(candidates) do
            if vim.fn.isdirectory(p) == 1 then
                return p
            end
        end
    end

    -- macOS: OneDrive 客户端有多个常见安装位置
    if get_os() == "macos" then
        local candidates = {
            home_dir() .. "/Library/CloudStorage/OneDrive-Personal",
            home_dir() .. "/OneDrive - Personal",
            home_dir() .. "/OneDrive",
        }
        for _, p in ipairs(candidates) do
            if vim.fn.isdirectory(p) == 1 then
                return p
            end
        end
    end

    -- Linux（如通过 rclone 同步）或 fallback
    return home_dir() .. "/OneDrive"
end

local nvim_frontend = get_nvim_frontend()

local activate_neovim_frontend = function()
    if not nvim_frontend then
        return
    end
    local focus_apis = {
        wt_wsl = function()
            log.debug("activate_neovim.wsl()")
            activate_windows_terminal()
        end,
        iterm2 = function()
            log.debug("activate_neovim.iterm2, session_id=" .. get_iterm_session_id())
            focus_iterm_by_session_id(get_iterm_session_id())
        end,
        neovide = function()
            local focus_pid = function(pid)
                -- log("focus_pid(" .. pid .. ")")
                local script = string.format(
                    [[
                    osascript -e 'tell application "System Events" to set frontmost of every process whose unix id is %d to true'
                    ]],
                    pid
                )
                os.execute(script)
            end
            -- log("activate_neovim.neovide()")
            local neovide_pid = utils.neovide_pid
            if neovide_pid then
                focus_pid(neovide_pid)
            end
        end,
    }
    if focus_apis[nvim_frontend] then
        focus_apis[nvim_frontend]()
    end
end

return {
    get_sessions = get_sessions,
    get_recent_files = get_recent_files,
    search_visual_selection = search_visual_selection,
    -- activate_windows_terminal = activate_windows_terminal,
    highlight_and_fadeout = highlight_and_fadeout,
    paste_yanked_select = paste_yanked_select,
    indent_selected_lines = indent_selected_lines,
    paste_and_indent = paste_and_indent,
    get_hl = get_hl,
    log = log,
    generate_snippets = generate_snippets,
    get_env = get_env,
    map = map,
    map_filter = map_filter,
    filter_path = filter_path,
    first_n = first_n,
    remove_prefix = remove_prefix,
    file_exists = file_exists,
    shorten_path = shorten_path,
    in_wsl = in_wsl(),
    in_macos = in_macos(),
    in_linux = in_linux(),
    get_os = get_os,
    get_iterm_session_id = get_iterm_session_id,
    get_wt_pid = get_wt_pid,
    -- focus_iterm = focus_iterm,
    get_neovide_pid = get_neovide_pid,
    home_dir = home_dir,
    path = path,
    copy_entire_file = copy_entire_file,
    strip_windows_paths = strip_windows_paths,
    get_nvim_frontend = get_nvim_frontend,
    is_temporary_buffer = is_temporary_buffer,
    get_onedrive_root = get_onedrive_root,
    activate_neovim_frontend = activate_neovim_frontend,
}
