return {
    url = "git@github.com:gaoqiangks/local-history.nvim",
    opts = {
        enabled = true,
        save_on = { "BufWritePost", "FocusLost" },
        root_dir = utils.get_onedrive_root() .. "/WorkSpace/nvim-local-history",
        max_file_size_kb = 10240,
        -- Only used when save_on contains change events
        on_change_debounce_ms = 100000,

        -- Minimum interval between two snapshots for the same file
        min_snapshot_interval_ms = 100000,

        notify = true,

        -- Retention policies
        max_entries_per_file = 2000,
        retention_days = 36500,
    },
}
