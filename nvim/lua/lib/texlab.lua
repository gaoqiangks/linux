-- file: texlab.lua
local texlab_client = nil

local texlab_build_status = vim.tbl_add_reverse_lookup {
    Success = 0,
    Error = 1,
    Failure = 2,
    Cancelled = 3,
}

local texlab_forward_status = vim.tbl_add_reverse_lookup {
    Success = 0,
    Error = 1,
    Failure = 2,
    Unconfigured = 3,
}

local function buf_search()
    local bufnr = vim.api.nvim_get_current_buf()
    local params = {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = { line = vim.fn.line '.' - 1, character = vim.fn.col '.' },
    }
    if texlab_client then
        texlab_client.request('textDocument/forwardSearch', params, function(err, result)
            if err then
                error(tostring(err))
            end
        end, bufnr)
    else
        print 'method textDocument/forwardSearch is not supported by any servers active on the current buffer'
    end
end


local function buf_build()
    local bufnr = vim.api.nvim_get_current_buf()
    local params = {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    }
    if texlab_client then
        texlab_client.request('textDocument/build', params, function(err, result)
            if err then
                error(tostring(err))
            end
        end, bufnr)
    else
        print('Method textDocument/build is not supported by any servers active on the current buffer.')
    end
end

function TexlabInverseSearch(filename, line)
    local serverlists = vim.fn.system("find ${XDG_RUNTIME_DIR:-${TMPDIR}nvim.${USER}}/nvim* -type s")
    local servers = vim.split(serverlists, "\n")
    local cmd = string.format(":lua TexlabPerformInverseSearch(\"%s\", %d)", filename, line)
    for _, server in ipairs(servers) do
        local ok, socket = pcall(vim.fn.sockconnect, 'pipe', server, { rpc = 1 })
        if ok then
            vim.fn.rpcnotify(socket, 'nvim_command', cmd)
        end
    end
end

local function GetLaTeXPackages()
    local params = {
        textDocument = { uri = vim.uri_from_bufnr(0) }
    }

    vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result, ctx, config)
        if err then return end
        local packages = {}
        for _, symbol in ipairs(result or {}) do
            if symbol.name:match('\\usepackage') then
                -- 提取包名（简化处理，可能需要根据实际格式调整）
                local pkg = symbol.name:match('{(.-)}')
                if pkg then table.insert(packages, pkg) end
            end
        end
        print('引用的包：' .. table.concat(packages, ', '))
    end)
end

-- 提取当前 buffer 所有 \usepackage 的包名
local function list_tex_packages()
    local params = vim.lsp.util.make_text_document_params()

    log("listing TeX packages in the current buffer...")
    texlab_client.request("textDocument/documentSymbol", params, function(err, result, ctx, _)
        log("LSP documentSymbol request.")
        if err then
            vim.notify("LSP 请求出错: " .. err.message, vim.log.levels.ERROR)
            log("lsp request error: " .. err.message)
            return
        end
        if not result then
            vim.notify("没有返回 documentSymbol 结果", vim.log.levels.WARN)
            log("No documentSymbol result returned.")
            return
        end

        local packages = {}

        -- 递归遍历符号树
        local function traverse(symbols)
            for _, sym in ipairs(symbols) do
                -- texlab 对命令的 kind 通常是 255 (Command)
                if sym.name == "usepackage" or sym.name == "\\usepackage" then
                    -- sym.detail 里通常包含参数，例如 "{amsmath, amssymb}"
                    if sym.detail then
                        for pkg in sym.detail:gmatch("{([^}]*)}") do
                            for name in pkg:gmatch("[^,%s]+") do
                                table.insert(packages, name)
                            end
                        end
                    end
                end
                if sym.children then
                    traverse(sym.children)
                end
            end
        end

        traverse(result)

        if #packages == 0 then
            vim.notify("未找到任何 \\usepackage", vim.log.levels.INFO)
            log("No packages found in the current TeX file.")
        else
            vim.notify("当前文件引用的包: " .. table.concat(packages, ", "))
            log("Packages used in the current TeX file: " .. table.concat(packages, ", "))
        end
    end)
end

local function texlab_on_attach(client_id, bufnr)
    texlab_client = client_id
    vim.api.nvim_create_user_command("TexlabView", buf_search, { desc = 'TexlabView' })
    -- local client = vim.lsp.get_client_by_id(client_id)
    -- if client.name == "texlab" then
    vim.api.nvim_buf_create_user_command(bufnr, "TexLabChangeEnv", function(opts)
        local pos = vim.api.nvim_win_get_cursor(0)
        texlab_client.request("workspace/executeCommand", {
            command = "texlab.changeEnvironment",
            arguments = { {
                textDocument = vim.lsp.util.make_text_document_params(),
                position = { line = pos[1] - 1, character = pos[2] },
                newName = opts.args,
            } },
        })
    end, { nargs = 1 })
    -- 注册一个命令 :ListTexPackages
    vim.api.nvim_create_user_command("ListTexPackages", GetLaTeXPackages, {
        desc = "列出当前 TeX 文件引用的所有包（通过 texlab documentSymbol）"
    })
    -- end
    -- vim.api.nvim_create_user_command("TexLabChangeEnv", function(opts)
    --     local params = {
    --         command = "texlab.changeEnvironment",
    --         arguments = { {
    --             textDocument = vim.lsp.util.make_text_document_params(),
    --             position = vim.api.nvim_win_get_cursor(0) and {
    --                 line = vim.api.nvim_win_get_cursor(0)[1] - 1,
    --                 character = vim.api.nvim_win_get_cursor(0)[2],
    --             },
    --             newName = opts.args, -- 从命令参数获取新环境名
    --         } },
    --     }
    --     log(texlab_client)
    --     texlab_client.request(params.command, params.arguments, function(err, result) end)
    --     -- vim.lsp.buf.execute_command(params)
    -- end, {
    --     nargs = 1,
    -- })
    local keymap = vim.api.nvim_buf_set_keymap
    keymap(bufnr, "n", "<leader>Lv", ":TexlabView<CR>", { noremap = true, silent = true, desc = "TexlabView" })
end

-- File: texlab.lua
-- Helper function to find a window that contains the target buffer in a given tabpage.
local function find_window_in_tab(tab, buffer)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if vim.api.nvim_win_get_buf(win) == buffer then
            return win
        end
    end
    return nil
end

-- Note that the function has to be public.
function TexlabPerformInverseSearch(filename, line)
    -- Check if Texlab is running in this instance.
    if not texlab_client then return end
    filename = vim.fn.resolve(filename)
    local buf = vim.fn.bufnr(filename)

    -- If the buffer is not loaded, load it and open it in the current window.
    if not vim.api.nvim_buf_is_loaded(buf) then
        buf = vim.fn.bufadd(filename)
        vim.fn.bufload(buf)
        vim.api.nvim_win_set_buf(0, buf)
    end

    -- Search buffer, starting from the current tab.
    local target_win;
    local target_tab = vim.api.nvim_get_current_tabpage()
    target_win = find_window_in_tab(target_tab, buf)

    if target_win == nil then
        -- Search all tabs and use the first one.
        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            target_win = find_window_in_tab(tab, buf)
            if target_win ~= nil then
                target_tab = tab
                break
            end
        end
    end

    -- Switch to target tab, window, and set cursor.
    vim.api.nvim_set_current_tabpage(target_tab)
    vim.api.nvim_set_current_win(target_win)
    vim.api.nvim_win_set_cursor(target_win, { line, 0 })
end

-- 发送 textDocument/documentSymbol 请求给当前 buffer attach 的 LSP（比如 texlab）
vim.api.nvim_create_user_command("TestDocSymbols", function()
    local params = vim.lsp.util.make_text_document_params()
    log("Sending textDocument/documentSymbol request...")

    vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result, ctx, _)
        log("LSP documentSymbol request callback.")
        if err then
            -- vim.notify("LSP 错误: " .. err.message, vim.log.levels.ERROR)
            log("LSP request error: " .. err.message)
            return
        end
        if not result or vim.tbl_isempty(result) then
            log("No symbols returned from LSP.")
            -- vim.notify("没有返回任何符号", vim.log.levels.WARN)
            return
        end

        -- 打印原始结果
        log("Document symbols result:" .. vim.inspect(result))
        -- vim.notify(vim.inspect(result))
    end)
end, { desc = "向 LSP 发送 textDocument/documentSymbol 请求" })

vim.api.nvim_create_user_command("TTestDocSymbols", function()
    local params = vim.lsp.util.make_text_document_params()
    for _, client in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
        print("Found client:", client.name)
        if client.name == "texlab" then
            client.request("textDocument/documentSymbol", params, function(err, result)
                -- print("Callback from texlab")
                log("Callback from texlab")
                if err then
                    log("Error from texlab:" .. err.message)
                    -- print("Error:", err.message)
                    return
                end
                log("Result from texlab:" .. vim.inspect(result))
                -- print(vim.inspect(result))
            end, 0)
        end
    end
end, {})

local M = {}
M.on_attach = texlab_on_attach
M.server_conf = {
    -- Regular Texlab configuration
}
return M
