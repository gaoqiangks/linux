return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-ui-select.nvim",
        "LukasPietzschmann/telescope-tabs",
        -- optional but recommended
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
        },
    },
    lazy = false,
    -- dependencies = { 'gaoqiangks/plenary.nvim'},
    -- enabled = false,
    opts = {
        pickers = {
            colorscheme = {
                enable_preview = true,
            },
        },
    },
    config = function()
        log.debug("telescope.lua: config 开始")
        local actions = require("telescope.actions")
        require("telescope").setup({
            defaults = {
                mappings = {
                    i = {
                        ["<esc>"] = actions.close,
                        ["<A-q>"] = function(prompt_bufnr)
                            vim.cmd("cquit" .. alt_q_exit_code)
                        end,
                        ["<A-p>"] = actions.move_selection_previous,
                        ["<A-n>"] = actions.move_selection_next,
                    },
                    n = {
                        ["<A-q>"] = function(prompt_bufnr)
                            vim.cmd("cquit" .. alt_q_exit_code)
                        end,
                    },
                },
            },
            pickers = {
                colorscheme = {
                    enable_preview = true,
                },
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({}),
                },
            },
        })
        require("telescope").load_extension("ui-select")
        require("telescope").load_extension("fzf")
        require("telescope").load_extension("telescope-tabs")
        log.debug("telescope.lua: 扩展加载完成（ui-select, fzf, telescope-tabs）")
        -- require("telescope").load_extension("projects")
        local builtin = require("telescope.builtin")
        keyset("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
        keyset("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
        keyset("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
        keyset("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
        -- persisted.nvim
        keyset("n", "<A-s>", "<cmd>Telescope persisted<cr>", { silent = true, remap = false, desc = "查找会话" })
        keyset(
            "n",
            "<leader>fs",
            "<cmd>Telescope persisted<cr>",
            { silent = true, remap = false, desc = "查找会话" }
        )
        keyset("n", "<leader>ff", "<cmd>Telescope fd<cr>", { silent = true, remap = false, desc = "查找文件" })
        keyset(
            "n",
            "<leader>ft",
            "<cmd>lua require('telescope-tabs').list_tabs()<cr>",
            { silent = true, remap = false, desc = "查找tab" }
        )
    end,
}
