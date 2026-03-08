#!/usr/bin/env lua
-- 引入 cjson 库
local cjson = require("cjson")
local inspect = require("inspect").inspect

-- 定义读取文件内容的函数
local function read_file(file_path)
    local file, err = io.open(file_path, "r")
    if not file then
        error("无法打开文件: " .. err)
    end
    local content = file:read("*a") -- 读取整个文件内容
    file:close()
    return content
end

function quotes(arg)
    return '"' .. arg .. '"'
end

local macro_snip_body = function(key, name, prefix, snippet_code, priority)
    local snippet = "\n\n"
    snippet = snippet .. "\t" .. quotes(key) .. ":{\n"
    snippet = snippet .. "\t\t" .. quotes("prefix") .. ":" .. '"' .. prefix .. '",\n'
    snippet = snippet .. "\t\t" .. '"body":[\n'
    snippet = snippet .. "\t\t\t\"\\\\" .. snippet_code .. "\"\n"
    snippet = snippet .. "\t\t],\n\t\t"
    snippet = snippet .. [["luasnip": {"priority": ]] .. priority .. "} \n\t}"
    return snippet
end

local env_snip_body = function(key, name, prefix, snippet_code, priority)
    local snippet = "\n\n"
    snippet = snippet .. "\t" .. quotes(key) .. ":{\n"
    snippet = snippet .. "\t\t" .. quotes("prefix") .. ":" .. '"' .. prefix .. '",\n'
    snippet = snippet .. "\t\t" .. '"body":[\n'
    snippet_code = "\\\\begin{" .. name .. '}",\n\t\t\t\t"\\t' .. snippet_code .. '",\n\t\t\t"\\\\end{' .. name .. "}"
    snippet = snippet .. '\t\t\t"' .. snippet_code .. '"\n'
    snippet = snippet .. "\t\t],\n\t\t"
    snippet = snippet .. [["luasnip": {"priority": ]] .. priority .. "} \n\t}"
    return snippet
end

local get_snip_data = function(name, format, s)
    local star = false
    local param = false
    local snippet_code = ""
    local key = name .. format
    -- c.snippet中的字符串\n已经被转转义成了换行
    if s then
        snippet_code = s:gsub("\\", "\\\\")
        snippet_code = snippet_code:gsub("\n", "\\n")
        snippet_code = snippet_code:gsub("\t", "\\t")
        -- print("snippet_code= "..snippet_code)
    end
    if key:find("^%w+%s*%*") then
        star = true
    end
    if key:find("^%w+.*%[") then
        param = true
    end

    local prefix = name
    if star then
        prefix = name:gsub("%*", "")
        prefix = "*" .. prefix
    end
    local priority = 1000
    if star then
        priority = 2000
    elseif param then
        priority = 1000
    else
        priority = 3000
    end
    return key, name, prefix, snippet_code, priority
end
--接受三个参数, name是命令的名字, format是命令的参数格式, s是命令的snippet
--比如对于newcommand{}{}, name = newcommand, format = {}{}
local macro_to_snippet = function(name, format, s, base_priority)
    local key, n, prefix, snippet_code, priority = get_snip_data(name, format, s)
    if priority then
        priority = priority + base_priority
    else
        priority = base_priority
    end
    if snippet_code == "" then
        snippet_code = n .. format
    end
    return macro_snip_body(key, n, prefix, snippet_code, priority)
end


--接受三个参数, name是命令的名字, format是命令的参数格式, s是命令的snippet
--比如对于newcommand{}{}, name = newcommand, format = {}{}
local env_to_snippet = function(name, format, s, base_priority)
    local key, n, prefix, snippet_code, priority = get_snip_data(name, format, s)
    if snippet_code == "" then
        snippet_code = "$1"
    end
    if priority then
        priority = priority + base_priority
    else
        priority = base_priority
    end
    return env_snip_body(key, n, prefix, snippet_code, priority)
end
-- 主逻辑
local function lw_commands_to_snippets(file_path, base_priority)
    -- JSON 文件路径
    -- 读取 JSON 文件内容
    local json_content = read_file(file_path)

    -- 将 JSON 字符串解析为 Lua 表
    local commands = cjson.decode(json_content)
    local total_macros = 0
    for _, _ in pairs(commands) do
        total_macros = total_macros + 1
    end
    local idx = 0
    local snippets = {}
    for macro, c in pairs(commands) do
        local format = ""
        if macro:match("^%w") then
            name, format = macro:match("^(%w*%*?)(%W*)$")
        end
        format = format or ""
        local snippet = macro_to_snippet(name, format, c and c.snippet, base_priority)
        table.insert(snippets, snippet)
    end
    print("{")
    for _, snippet in pairs(snippets) do
        idx = idx + 1
        if idx ~= total_macros then
            snippet = snippet .. ","
        end
        print(snippet)
    end
    print("}")
end



local function lw_packages_to_snippets(file_path, base_priority)
    -- JSON 文件路径
    -- 读取 JSON 文件内容
    local json_content = read_file(file_path)

    -- 将 JSON 字符串解析为 Lua 表
    local lua_table = cjson.decode(json_content)
    local macros = lua_table.macros
    local envs = lua_table.envs
    local total = 0
    for _, _ in pairs(macros) do
        total = total + 1
    end
    for _, _ in pairs(envs) do
        total = total + 1
    end
    local idx = 0
    local snippets = {}
    for _, macro in ipairs(macros) do
        local name = macro.name
        local format = ""
        if macro.arg and macro.arg.format then
            format = macro.arg.format
        end
        local snippet = macro_to_snippet(name, format, macro.arg and macro.arg.snippet, base_priority)
        table.insert(snippets, snippet)
    end
    for _, env in ipairs(envs) do
        local name = env.name
        local format = ""
        if env.arg and env.arg.format then
            format = env.arg.format
        end
        local snippet = env_to_snippet(name, format, env.arg and env.arg.snippet, base_priority)
        table.insert(snippets, snippet)
    end
    print("{")
    for _, snippet in pairs(snippets) do
        idx = idx + 1
        if idx ~= total then
            snippet = snippet .. ","
        end
        print(snippet)
    end
    print("}")
end

local main = function(a)
    local f = a[1]
    local file = a[2]
    local base_priority = a[3] or 0
    if f == "cmd" then
        lw_commands_to_snippets(file, base_priority)
        return
    end
    if f == "pkg" then
        lw_packages_to_snippets(file, base_priority)
        return
    end
    print("usage: lw_to_snippets.lua cmd file base_priority")
    print("         convert commands.json to vscode snippets.")
    print("       lw_to_snippets.lua pkg file base_priority")
    print("         convert pkg.json to vscode snippets.")
end

main(arg)
