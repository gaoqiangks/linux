return {
    "goolord/alpha-nvim",
    -- dependencies = { 'echasnovski/mini.icons' },
    enabled = false,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local startify = require("alpha.themes.startify")
        -- available: devicons, mini, default is mini
        -- if provider not loaded and enabled is true, it will try to use another provider
        startify.file_icons.provider = "devicons"
        require("alpha").setup(
            {
                -- required

                -- element type
                type = "button",
                -- the text to display
                val = "string",
                -- what to do when the button is pressed
                -- useful functions:
                -- local key = vim.api.nvim_replace_termcodes(shortcut, true, false, true)
                -- vim.api.nvim_feedkeys(key, "normal", false)
                on_press = function() end,

                -- optional
                opts = {
                    -- define a buffer-local keymap for this element
                    -- accepts the arguments for 'nvim_set_keymap' as an array
                    -- normally pairs with an 'on_press' function that feeds the lhs
                    -- keys (see alpha.dashboard.button implementation)
                    -- keymap = { {mode}, {lhs}, {rhs}, {*opts} }

                    position = "center",
                    -- hl = "hl_group" | { { "hl_group", 0, -1 } } | { { { "hl_group", 0, -1 } } },

                    shortcut = "string",
                    align_shortcut = "left",
                    hl_shortcut = "hl_group",

                    -- starting at the first character,
                    -- from 0 to #shortcut + #val,
                    -- place the cursor on this row
                    cursor = 0,
                    -- how wide to pad the button.
                    -- useful if position = "center"
                    width = 50,
                    -- when `shrink_margin` is true, the margin will
                    -- shrink when the window width is too small to display
                    -- the full width margin + the full element.
                    -- 'dashboard' has this set to true, since it has huge margins and
                    -- small layout elements, and 'startify' has this set to
                    -- false, since it has huge layout elements and a small margin
                    -- defaults to true
                    shrink_margin = true
                }
            }
        )
    end,
}
