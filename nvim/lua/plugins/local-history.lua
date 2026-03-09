return {
    url = "git@github.com:gaoqiangks/local-history.nvim",
    opts = {
        enabled = true,
        profile = false,
        save_on = { "BufWritePost", "FocusLost" },
        root_dir = utils.get_onedrive_root() .. "/WorkSpace/nvim-local-history",
        max_file_size_kb = 1024 * 100,
        -- Only used when save_on contains change events
        on_change_debounce_ms = 10 * 60 * 1000,

        -- Minimum interval between two snapshots for the same file
        min_snapshot_interval_ms = 10 * 60 * 1000,

        notify = false,

        -- Retention policies
        max_entries_per_file = -1,
        retention_days = -1,
        dedupe_enabled = false, -- 不去重
        cleanup_enabled = false, -- 不清理
    },
}
