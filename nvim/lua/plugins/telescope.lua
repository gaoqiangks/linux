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
        oldfiles_shorten_enabled = true,
        pickers = {
            colorscheme = {
                enable_preview = true,
            },
        },
    },
    config = function(opts)
        log.debug("telescope.lua: config 开始")
        local actions = require("telescope.actions")
        
        -- Variable to control whether to shorten paths in oldfiles
        local oldfiles_shorten_enabled = opts.oldfiles_shorten_enabled
        
        -- Function to toggle the shorten setting
        local toggle_oldfiles_shorten = function()
            oldfiles_shorten_enabled = not oldfiles_shorten_enabled
            if oldfiles_shorten_enabled then
                vim.notify("Telescope oldfiles: Short paths enabled", vim.log.levels.INFO)
            else
                vim.notify("Telescope oldfiles: Full paths enabled", vim.log.levels.INFO)
            end
        end
        
        -- Path display function for oldfiles
        local oldfiles_path_display = function(_, path)
            -- Replace home directory with ~
            local home = os.getenv("HOME")
            if home and path:sub(1, #home) == home then
                path = "~" .. path:sub(#home + 1)
            end
            -- Split the path into components
            local parts = {}
            for part in path:gmatch("[^/]+") do
                table.insert(parts, part)
            end
            -- If no parts, return original path
            if #parts == 0 then
                return path
            end
            -- Process each part
            local processed_parts = {}
            for i, part in ipairs(parts) do
                if i == #parts then
                    -- Last part (filename) - keep it完整
                    table.insert(processed_parts, part)
                else
                    -- Directory part - take first character
                    -- Use vim.fn.strcharpart to get first UTF-8 character
                    local first_char = vim.fn.strcharpart(part, 0, 1)
                    table.insert(processed_parts, first_char)
                end
            end
            -- Reconstruct the path
            local shortened = table.concat(processed_parts, "/")
            return shortened
        end
        
        require("telescope").setup({
            defaults = {
                -- 关闭预览窗口以提升性能
                preview = false,
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
                oldfiles = {
                    path_display = function(self, path)
                        if oldfiles_shorten_enabled then
                            return oldfiles_path_display(self, path)
                        else
                            -- Return the path as-is (Telescope will use default formatting)
                            return path
                        end
                    end,
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
        
        -- Custom function to display oldfiles with shortened paths
        local oldfiles_shorten = function()
            builtin.oldfiles()
        end

        keyset("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
        keyset("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
        keyset("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
        keyset("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
        keyset("n", "<leader>fo", oldfiles_shorten, { desc = "Telescope old files with shortened paths" })
        -- Add a keymap to toggle the shorten setting
        keyset("n", "<leader>fos", toggle_oldfiles_shorten, { desc = "Toggle oldfiles path shortening" })
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
