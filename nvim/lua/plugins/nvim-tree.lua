local map = utils.map

local helper = {}

-- function helper.on_attach(bufnr)
--     require("nvim-tree.api").config.mappings.default_on_attach(bufnr)
--
--     map.unregister("n", "g?", { buffer = bufnr })
--     map.unregister("n", "<c-x>", { buffer = bufnr })
--
--     map.bulk_register({
--         {
--             mode = { "n" },
--             lhs = "?",
--             rhs = require("nvim-tree.api").tree.toggle_help,
--             options = { silent = true, buffer = bufnr, nowait = true },
--             description = "Toggle help document",
--         },
--         {
--             mode = { "n" },
--             lhs = "<c-s>",
--             rhs = require("nvim-tree.api").node.open.horizontal,
--             options = { silent = true, buffer = bufnr, nowait = true },
--             description = "Open: Horizontal Spli",
--         },
--     })
-- end

opts = {
    disable_netrw = false,
    hijack_netrw = false,
    hijack_cursor = true,
    update_cwd = true,
    reload_on_bufenter = true,
    auto_reload_on_write = true,
    -- on_attach = helper.on_attach,
    notify = {
        threshold = vim.log.levels.WARN,
    },
    update_focused_file = {
        enable = true,
        update_cwd = false,
    },
    view = {
        side = "left",
        width = 30,
        signcolumn = "yes",
    },
    diagnostics = {
        enable = false,
        show_on_dirs = true,
        -- icons = {
        --     hint = icons.Hint,
        --     info = icons.Info,
        --     warning = icons.Warn,
        --     error = icons.Error,
        -- },
    },
    actions = {
        use_system_clipboard = true,
        change_dir = {
            enable = true,
            global = true,
            restrict_above_cwd = false,
        },
        open_file = {
            resize_window = false,
            window_picker = {
                enable = true,
            },
        },
    },
    trash = {
        cmd = "trash",
        require_confirm = true,
    },
    filters = {
        dotfiles = true,
        custom = {
            "\\.fls",
            "\\.xdv",
            "\\.aux",
            "\\.blg",
            "\\.bcf",
            "\\.fdb_latexmk",
            "\\.idx",
            "\\.ilg",
            "\\.ind",
            "\\.log",
            "\\.pdf",
            "\\.run.xml",
            "\\.synctex",
            "\\.toc",
            "\\.aux",
            "\\.bbl",
            "\\.blg",
            "\\.ilg",
            "\\.thm",
            "\\.idx",
            "\\.ind",
            "\\.lof",
            "\\.lot",
            "\\.out",
            "\\.toc",
            "\\.acn",
            "\\.acr",
            "\\.alg",
            "\\.glg",
            "\\.glo",
            "\\.gls",
            "\\.fls",
            "\\.log",
            "\\.fdb_latexmk",
            "\\.snm",
            "\\.synctex(busy)",
            "\\.synctex.gz(busy)",
            "\\.nav",
            "\\.vrb",
            "\\.bcf",
            "\\.xdv",
            "\\.synctex.gz",
            "\\.xml",
            "\\.bbl",
            "\\*.synctex",
            "\\*.run.xml",
        },
    },
    renderer = {
        add_trailing = true,
        highlight_git = true,
        root_folder_label = false,
        highlight_opened_files = "none",
        icons = {
            show = {
                file = true,
                folder = true,
                folder_arrow = true,
                git = false,
            },
            glyphs = {
                default = "",
                symlink = "",
                git = {
                    unstaged = "",
                    staged = "",
                    unmerged = "",
                    renamed = "凜",
                    untracked = "",
                    deleted = "",
                    ignored = "",
                },
                folder = {
                    arrow_open = "",
                    arrow_closed = "",
                    default = "",
                    open = "",
                    empty = "",
                    empty_open = "",
                    symlink = "",
                    symlink_open = "",
                },
            },
        },
    },
}

opts2 = {
    sort = {
        sorter = "case_sensitive",
    },
    on_attach = single_click,
    view = {
        width = 30,
    },
    renderer = {
        group_empty = true,
    },
    filters = {
        dotfiles = true,
        custom = {
            "\\.fls",
            "\\.xdv",
            "\\.aux",
            "\\.blg",
            "\\.bcf",
            "\\.fdb_latexmk",
            "\\.idx",
            "\\.ilg",
            "\\.ind",
            "\\.log",
            "\\.pdf",
            "\\.run.xml",
            "\\.synctex",
            "\\.toc",
            "\\.aux",
            "\\.bbl",
            "\\.blg",
            "\\.ilg",
            "\\.thm",
            "\\.idx",
            "\\.ind",
            "\\.lof",
            "\\.lot",
            "\\.out",
            "\\.toc",
            "\\.acn",
            "\\.acr",
            "\\.alg",
            "\\.glg",
            "\\.glo",
            "\\.gls",
            "\\.fls",
            "\\.log",
            "\\.fdb_latexmk",
            "\\.snm",
            "\\.synctex(busy)",
            "\\.synctex.gz(busy)",
            "\\.nav",
            "\\.vrb",
            "\\.bcf",
            "\\.xdv",
            "\\.synctex.gz",
            "\\.xml",
            "\\.bbl",
            "\\*.synctex",
            "\\*.run.xml",
        },
    },
}
local function single_click(bufnr)
    local single_click_do = function(bufnr)
        local row, col = vim.fn.getmousepos()
    end
    vim.keymap.set("n", "<LeftRelease>", function()
        local api = require("nvim-tree.api")
        local tree = api.tree
        local mouse_pos = vim.fn.getmousepos()
        local row, col = mouse_pos.screenrow, mouse_pos.screencol
        -- log("mouse_pos= " .. vim.inspect(mouse_pos))
        -- log("row= " .. row .. "  col = " .. col)
        local cur_row, cur_col = vim.fn.getpos(".")
        vim.fn.cursor({ row, col })
        local node = tree.get_node_under_cursor()
        -- log("node = " .. vim.inspect(node))

        if node then
            -- api.node.open.edit()
            api.node.open.tab(node, {})
        end
        api.config.mappings.default_on_attach(bufnr)
    end, {})
end
return {
    "nvim-tree/nvim-tree.lua",
    -- enabled = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
        -- disable netrw at the very start of your init.lua
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
    end,
    config = function()
        -- optionally enable 24-bit colour
        vim.opt.termguicolors = true
        -- vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
        vim.keymap.set("n", "<leader>t", "<Esc>:NvimTreeToggle<CR>", { silent = true, desc = "Toggle NvimTree" })

        -- OR setup with some options
        require("nvim-tree").setup(opts)
        -- map.bulk_register(
        --     { {
        --         mode = { "n" },
        --         lhs = "<leader>1",
        --         rhs = function()
        --             require("nvim-tree.api").tree.toggle({
        --                 find_file = true,
        --                 focus = true,
        --             })
        --         end,
        --         options = { silent = true },
        --         description = "Open File Explorer",
        --     } })
    end,
}
