-- 禁用 LSP 进度通知（可选）, 必须放在最前面.
-- vim.lsp.handlers["$/progress"] = function() end
-- vim.g.lsp_progress_enabled = false

return {

    {
        -- 2. LSP 核心配置
        "neovim/nvim-lspconfig",
        -- enabled = false,
        dependencies = {
            { "williamboman/mason.nvim", config = true },
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            -- vim.lsp.enable_progress(false)

            -- 获取补全能力
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- vim.lsp.handlers["$/progress"] = function() end
            -- vim.lsp.handlers["$/progress"] = function() end

            -- 使用原生 API 定义全局基础配置
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            -- --- 针对各语言服务器的现代配置 (Neovim 0.11 风格) ---

            -- Lua (lua_ls)
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = {
                            globals = { "vim" },
                            disable = { "missing-fields" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            -- 注意：有了 lazydev，通常不需要手动写 nvim_get_runtime_file
                        },
                    },
                },
            })

            -- Python (basedpyright)
            vim.lsp.config("basedpyright", {
                settings = {
                    basedpyright = {
                        analysis = { diagnosticMode = "openFilesOnly" },
                    },
                },
            })

            -- 其他服务器 (gopls, rust_analyzer, clangd)
            -- vim.lsp.config("gopls", { settings = { gopls = { gofumpt = true } } })
            vim.lsp.config("rust_analyzer", { settings = { ["rust-analyzer"] = { check = { command = "clippy" } } } })
            vim.lsp.config("clangd", { cmd = { "clangd", "--background-index" } })

            -- --- 激活服务器 ---
            -- 核心：初始化 Mason-LSPConfig
            -- v2.0 会自动 enable 已安装的服务器，无需再手动写循环 setup
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "basedpyright", "vtsls", "rust_analyzer", "clangd" },
                -- 关键：开启自动激活
                automatic_enable = {
                    exclude = { "texlab" },
                },
            })

            -- 快捷键绑定 (LspAttach)
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(ev)
                    local opts = { buffer = ev.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                end,
            })
            -- vim.lsp.handlers["$/progress"] = function() end
        end,
    },
}
