local notify = require("mini.notify")
local keyset = vim.keymap.set
local ns_id = vim.api.nvim_create_namespace("BackSearchHL")

-- 每次编译完后, 把wsl下的synctex文件中的路径转换为windows下的路径
local synctex_path_to_win_setup = function()
    vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventCompileSuccess",
        group = vim.api.nvim_create_augroup("group_synctex_to_win", { clear = true }),
        callback = function()
            -- print("here  compile success")
            local main_tex = vim.b.vimtex.compiler.file_info.target:gsub("tex$", "synctex")
            -- -i后需要加'', 不然会生成一些备份文件
            local sed_cmd = "sed -i'' 's#/mnt/c/#C:/#g' \"" .. main_tex .. '"'
            vim.fn.system(sed_cmd)
        end,
    })
end

--inverse search的回调函数, 主要实现高亮当前行, 并实现淡出效果
local inverse_search_callback = function()
    vim.cmd("normal zz")
    log.debug("Inverse search callback triggered")

    -- vim.cmd("call b:vimtex.viewer.xdo_focus_vim()")

    local highlight_and_fadeout = utils.highlight_and_fadeout
    local env_inner = vim.fn["vimtex#env#get_inner"]()
    local env_name = env_inner and env_inner.name
    local env_equation_list = {
        ["equation"] = 1,
        ["align"] = 1,
        ["alignat"] = 1,
        ["gather"] = 1,
        ["multline"] = 1,
        ["split"] = 1,
        ["flalign"] = 1,
        ["equation*"] = 1,
        ["align*"] = 1,
        ["alignat*"] = 1,
        ["gather*"] = 1,
        ["multline*"] = 1,
        ["split*"] = 1,
        ["flalign*"] = 1,
    }
    local startl = vim.api.nvim_win_get_cursor(0)[1]
    local endl = startl
    -- 如果当前行在一个数学环境中, 则高亮这个环境
    if env_name and env_equation_list[env_name] then
        startl = env_inner.open.lnum
        endl = env_inner.close.lnum
    end
    local highlight_time = 2000 -- 默认高亮时间为 2000 毫秒（2 秒), 然后淡出
    highlight_and_fadeout({ startl = startl, endl = endl, ns = ns_id }, highlight_time)
    utils.activate_neovim_frontend()
end

local inverse_search_focus_setup = function(arg)
    vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventViewReverse",
        group = vim.api.nvim_create_augroup("group_inverse_search_focus", { clear = true }),
        callback = inverse_search_callback,
    })
end

-- 切换quickfix窗口的函数
local toggle_quickfix_window = function()
    local is_quickfix_open = function()
        for _, win in ipairs(vim.fn.getwininfo()) do
            if win.quickfix == 1 then
                return true
            end
        end
        return false
    end
    if is_quickfix_open() then
        vim.cmd("cclose")
    else
        vim.cmd("copen")
    end
end

--编译的时候显示一个转圈的通知
local function compiling_notification()
    local message = "Compiling..."
    local duration = 1000000000
    -- 定义转圈的图案
    local spinner_frames = { "⠋", "⠙", "⠸", "⠴", "⠦", "⠧", "⠇", "⠋" }
    local frame_count = #spinner_frames

    -- 显示初始通知
    local notif = notify.add(message .. " " .. spinner_frames[1])

    local i = 1
    local timer = vim.loop.new_timer()

    vim.api.nvim_create_autocmd("User", {
        pattern = { "VimtexEventCompileSuccess", "VimtexEventCompileFailed" },
        group = vim.api.nvim_create_augroup("group_compile_finished", { clear = true }),
        --每次执行完后必须删除这里的autocmd
        once = true,
        callback = function(ev)
            -- log("ev = " .. vim.inspect(ev))
            -- log("timer = " .. vim.inspect(timer))
            -- log("in callback notif = " .. vim.inspect(notif))
            pcall(function()
                duration = 0
                if ev.match == "VimtexEventCompileSuccess" then
                    message = "Compile Success"
                else
                    message = "Compile Failed"
                end
                -- 好像是vimtex的bug, VimtexEventCompileFailed会触发两次, 这样会导致notif已经被删除了, 但是这里还在更新
                -- 不是vimtex的bug, 不知道为什么有时候会执行两次
                notify.update(notif, { msg = message })
                -- notify.update(notif, { msg = message })
                timer:close()
                vim.defer_fn(function()
                    notify.remove(notif)
                end, 3000)
            end)
        end,
    })

    -- 定时器更新内容
    pcall(function()
        timer:start(
            0,
            100,
            vim.schedule_wrap(function()
                -- 更新显示内容
                i = (i % frame_count) + 1
                local new_message = message .. " " .. spinner_frames[i]
                notify.update(notif, { msg = new_message })

                -- 停止计时器
                duration = duration - 100
            end)
        )
    end)
end

-- 设置编译的时候的通知
local notification = function()
    vim.api.nvim_create_autocmd("User", {
        pattern = { "VimtexEventCompiling" },
        group = vim.api.nvim_create_augroup("group_notifications", { clear = true }),
        callback = compiling_notification,
    })
end

local wsl_set_viewers = function(arg)
    if not utils.in_wsl then
        return
    end
    vim.g.vimtex_view_general_viewer = "python3"
    vim.g.vimtex_view_general_options = "/mnt/c/Users/gaoqiang/OneDrive/programs/python/wsl_nvim_sumatrapdf.py"
        .. " "
        .. [[@tex @line @pdf]]
end

local macos_set_viewers = function(viewer)
    if not utils.in_macos then
        return
    end
    local viewers_setup = {
        sioyek = function()
            vim.g.vimtex_view_method = "sioyek"
            vim.g.vimtex_view_sioyek_exe = "/Applications/sioyek.app/Contents/MacOS/sioyek"
        end,
        skim = function()
            vim.g.vimtex_view_method = "skim"
            vim.g.vimtex_view_skim_activate = 1
        end,
    }
    viewers_setup[viewer]()
    -- vim.g.vimtex_view_sioyek_options = ""
end

-- 启动nvim后自动编译
-- 忘记了为什么需要这个函数了, 好像是因为windows terminal下打开多个文件太慢了, 会出现莫名其录的问题.
local auto_compile_setup = function()
    vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventInitPost",
        --只执行一次
        once = true,
        group = "group_auto_compile",
        --如果是加载一个session, 要把所有session都加载完了才开始编译
        --使用的是persisted.nvim插件管理session
        callback = function()
            if vim.g.SessionLoad then
                vim.api.nvim_create_autocmd("User", {
                    pattern = "PersistedLoadPost",
                    group = group_vimtex_auto_compile,
                    --只执行一次
                    once = true,
                    callback = function()
                        -- log("session loaded, compiling")
                        vim.cmd("VimtexCompile")
                    end,
                })
            else
                vim.cmd("VimtexCompile")
            end
        end,
    })
end

local right_click_menu_setup = function()
    local vimtex_menu_group = vim.api.nvim_create_augroup("VimtexRightClick", { clear = true })

    -- 统一定义添加菜单的逻辑
    local function add_latex_menu()
        if vim.bo.filetype == "tex" then
            -- 1. 同步菜单 (最上方)
            vim.cmd([[silent! amenu 10.100 PopUp.同步\ SyncTex <cmd>VimtexView<CR>]])

            -- 2. 编译菜单 (紧跟其后)
            vim.cmd([[silent! amenu 10.110 PopUp.编译\ Build <cmd>VimtexCompile<CR>]])

            -- 3. 分隔符
            vim.cmd([[silent! amenu 10.120 PopUp.-SyncSep- <Nop>]])
        end
    end

    -- 触发逻辑：处理正常打开、窗口进入
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        pattern = "tex",
        group = vimtex_menu_group,
        callback = add_latex_menu,
    })

    -- 触发逻辑：专门处理 persisted.nvim Session 加载
    vim.api.nvim_create_autocmd("User", {
        pattern = "PersistedLoadPost",
        group = vimtex_menu_group,
        callback = function()
            vim.schedule(add_latex_menu)
        end,
    })

    -- 清理逻辑：离开 tex 文件时移除所有相关菜单
    vim.api.nvim_create_autocmd("BufLeave", {
        pattern = "*",
        group = vimtex_menu_group,
        callback = function()
            vim.schedule(function()
                if vim.bo.filetype ~= "tex" then
                    vim.cmd([[silent! aunmenu PopUp.同步\ SyncTex]])
                    vim.cmd([[silent! aunmenu PopUp.编译\ Build]])
                    vim.cmd([[silent! aunmenu PopUp.-SyncSep-]])
                end
            end)
        end,
    })
end
return {
    -- url = "git@github.com:gaoqiangks/vimtex",
    "lervag/vimtex",
    ft = { "tex" },
    dependencies = {
        "nvim-mini/mini.notify",
    },
    -- 必须加上， 不然nvim --headless -c 的时候， inverse search功能会提示找不到VimtexInverseSearch这个命令
    lazy = false,
    -- enabled = false,
    -- init函数可以用来在加载插件之前设置一些全局变量
    init = function()
        vim.g.vimtex_env_toggle_math_map = {
            ["$"] = "equation",
            ["equation"] = "$",
        }

        if vim.g.vscode then
            vim.g.vimtex_compiler_enabled = 0
            vim.g.vimtex_doc_enabled = 0
            -- 如果vimtex_syntax_enabled=0, 那么ts$之类的功能不能使用
            vim.g.vimtex_toc_enabled = 0
            vim.g.vimtex_view_enabled = 0
            vim.g.vimtex_complete_enabled = 0
            vim.g.vimtex_doc_enabled = 0
            return
        end
        -- vim.g.vimtex_compiler_enabled = 0
        -- 禁用quickfix
        -- vim.g.vimtex_quickfix_enabled = 0
        vim.g.vimtex_format_enabled = 1
        -- 在新的tab中打开inverse search的文件
        vim.g.vimtex_view_reverse_search_edit_cmd = "tabedit"
        --不打印 Compilation Completed之类的信息
        vim.g.vimtex_compiler_silent = 1
        -- 永远不要自动打开quickfix窗口
        vim.g.vimtex_quickfix_mode = 0
        -- 有警告时不要自动打开quickfix窗口
        vim.g.vimtex_quickfix_open_on_warning = 0
        vim.g.vimtex_compiler_latexmk_engines = {
            _ = "-xelatex",
            pdfdvi = "-pdfdvi",
            pdfps = "-pdfps",
            pdflatex = "-pdf",
            luatex = "-lualatex",
            lualatex = "-lualatex",
            xelatex = "-xelatex",
        }
        --不要自动打开pdf-viewer
        vim.g.vimtex_view_automatic = 0
        vim.g.vimtex_compiler_latexmk = {
            -- aux_dir = "./aux_dir",
            out_dir = "",
            callback = 1,
            continuous = 1,
            executable = "latexmk",
            hooks = {},
            options = {
                "-verbose",
                "-file-line-error",
                "-synctex=-1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-pdf",
                "-verbose", --如果不加verbose的话, 如果当前pdf文件在adobe中打开了, 那么latexmk不会报错.
                -- "-e",                 -- -e表示可以使用perl变量
                -- "'$sleep_time = 30'", -- 两次编译之间的间隔时间, 单位是秒
                "-e",
                "'$makeindex=\"zhmakeindex -s "
                    .. utils.get_onedrive_root()
                    .. "/WorkSpace/settings/zhmakeindex/zhmakeindex.ist\"'",
            },
        }
        wsl_set_viewers()
        macos_set_viewers("sioyek")
    end,
    config = function()
        keyset("n", "eq", "ts$", { silent = true, remap = true })
        keyset("n", "99", "tsd", { silent = true, remap = true })
        keyset("n", "88", "tss", { silent = true, remap = true })
        -- vimtex中, ts$可以在inline和display数学公式之间切换.
        keyset("n", "<A-e>", toggle_quickfix_window, { silent = true, remap = false })
        keyset("n", "<A-v>", "<plug>(vimtex-view)", { silent = true, remap = false })
        keyset("n", "<A-c>", "<plug>(vimtex-clean-full)", { silent = true, remap = false })
        keyset("n", "<A-b>", "<plug>(vimtex-compile)", { silent = true, remap = false })
        if vim.g.vscode then
            return
        end
        inverse_search_focus_setup()
        -- auto_compile_setup()
        if in_wsl then
            synctex_path_to_win_setup()
        end
        notification()
        right_click_menu_setup()
    end,
}
