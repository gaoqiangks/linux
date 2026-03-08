#!/usr/bin/env lua
-- 引入 cjson 库
local cjson = require("cjson")

if true then
    print("未完成的代码")
    return
end
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

local function copy(args)
    return args[1]
end


-- 定义一个函数来读取并打印 a.txt 的内容
local function read_and_print(arg)
    -- 获取当前脚本的路径
    local script_path = debug.getinfo(1, "S").source:match("@(.*)")
    if not script_path then
        print("无法获取当前脚本路径")
        return
    end

    -- 提取脚本所在的目录
    local dir_path = script_path:match("(.*[/\\])")
    if not dir_path then
        dir_path = "./" -- 如果无法提取目录，则默认为当前目录
    end

    -- 构造目标文件路径
    local file_path = dir_path .. "/" .. arg

    -- 打开文件并读取内容
    local file = io.open(file_path, "r")
    if not file then
        print("无法打开文件: " .. file_path)
        return
    end

    -- print("文件内容如下：")
    for line in file:lines() do
        print(line)
    end

    -- 关闭文件
    file:close()
end

function vscode_snippet_to_luasnip(str)
    local pattern = "%$%{%d+:([^}]+)%}"
    local init = 1
    local idx = 1
    local luasnip = ""
    local t = ""
    while true do
        local start, last, c = string.find(str, pattern, init)
        if not start then
            t = str:sub(init, -1)
            t = "t(\"" .. t .. "\")"
            luasnip = luasnip .. t
            break
        end
        t = str:sub(init, start - 1)
        t = "t(\"" .. t .. "\"),\n"
        -- c="f(copy,\""..c.."\"),\n"
        i = "i(" .. idx .. ",\"" .. c .. "\"),\n"
        luasnip = luasnip .. t .. i
        init = last + 1
        idx = idx + 1
    end
    -- print(luasnip)
    return luasnip
end

-- local str = "\\\\parbox"
-- print(vscode_snippet_to_luasnip(str))

-- 主逻辑
local function main()
    -- JSON 文件路径
    local file_path = arg[1]

    -- 读取 JSON 文件内容
    local json_content = read_file(file_path)

    -- 将 JSON 字符串解析为 Lua 表
    local commands = cjson.decode(json_content)
    local total_cmds = 0
    for _, _ in pairs(commands) do
        total_cmds = total_cmds + 1
    end
    local idx = 0
    print([[ls.add_snippets("all",]])
    print("{")
    local snippets_normal = {}
    local snippets_param = {}
    local snippets_star = {}
    for cmd, c in pairs(commands) do
        local star = false
        local param = false
        local name = cmd
        if cmd:find("{%s*}") then
            cmd = cmd:gsub("{%s*}.*", "")
        end
        if cmd:find("[%s*]") then
            cmd = cmd:gsub("[%s*].*", "")
        end
        -- s("newcommand{", {
        --     t("\\newcommand"),
        --     -- Placeholder/Insert.
        --     i(1),
        --     t("}{"),
        --     i(2)
        --     t("}")
        -- }),
        -- local key = cmd

        local snippet_code = "\\\\" .. cmd
        -- c.snippet中的字符串\n已经被转转义成了换行
        if c and c.snippet then
            snippet_code = c.snippet:gsub("\\", "\\\\")
            snippet_code = snippet_code:gsub("\n", "\\n")
            snippet_code = "\\\\" .. snippet_code:gsub("\t", "\\t")
        end
        snippet_code = vscode_snippet_to_luasnip(snippet_code)
        if snippet_code:find("^\\\\%w+%s*%*") then
            star = true
        end
        if snippet_code:find("^\\\\%w+.*%[") then
            param = true
        end
        local snippet = "\n\n"
        local context = "{trig = \"" .. cmd .. "\", desc = \"_commands\"}"
        snippet = "s(" .. context .. ", {\n" .. snippet_code .. ",\n}),\n"
        snippet = snippet .. "\n\n"
        if star then
            table.insert(snippets_star, snippet)
        elseif param then
            table.insert(snippets_param, snippet)
        else
            table.insert(snippets_normal, snippet)
        end
    end
    --不带参数, 不带星号的命令权重最高, 其次是带星号不带参数的, 最后是带参数的
    for _, snippet in pairs(snippets_normal) do
        idx = idx + 1
        if idx ~= total_cmds then
            -- snippet = snippet .. ","
        end
        print(snippet)
    end
    for _, snippet in pairs(snippets_star) do
        idx = idx + 1
        if idx ~= total_cmds then
            -- snippet = snippet .. ","
        end
        print(snippet)
    end
    for _, snippet in pairs(snippets_param) do
        idx = idx + 1
        if idx ~= total_cmds then
            -- snippet = snippet .. ","
        end
        print(snippet)
    end
    print([[},{ key = "all", })]])
    print("end,")
    print("}")
end

-- 执行主函数
read_and_print("common_setup_luasnip.txt")
main()
