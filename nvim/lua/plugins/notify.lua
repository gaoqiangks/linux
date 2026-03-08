return {
    "rcarriga/nvim-notify",
    enabled = false,
    -- url = "git@github.com:gaoqiangks/nvim-notify.git",
    config = function()
        require("notify").setup({
            top_down = false,
            max_width = 30
        })
    end
}
