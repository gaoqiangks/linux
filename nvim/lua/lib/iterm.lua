-- iTerm2 integration utilities
-- Requires macOS + iTerm2

local M = {}

-- Parse ITERM_SESSION_ID env var (set by iTerm2 in every session).
-- Format: w{window_idx}t{tab_idx}p{pane_idx}:{session_uuid}
-- Returns a table with:
--   window_idx  (number, 0-based)
--   tab_idx     (number, 0-based)
--   pane_idx    (number, 0-based)
--   session_uuid (string)
-- Returns nil + error message on failure.
function M.get_iterm_ids()
    local raw = os.getenv("ITERM_SESSION_ID")
    if not raw then
        return nil, "ITERM_SESSION_ID not set – not running inside iTerm2"
    end

    local win, tab, pane, uuid = raw:match("^w(%d+)t(%d+)p(%d+):(.+)$")
    if not win then
        return nil, "Failed to parse ITERM_SESSION_ID: " .. raw
    end

    return {
        window_idx   = tonumber(win),
        tab_idx      = tonumber(tab),
        pane_idx     = tonumber(pane),
        session_uuid = uuid,
        raw          = raw,
    }
end

-- Use AppleScript to fetch iTerm2's internal window/tab/session IDs
-- for the session whose UUID matches the current ITERM_SESSION_ID.
-- Returns a table with:
--   window_id  (string)   – iTerm2 AppleScript window id
--   tab_id     (string)   – iTerm2 AppleScript tab id
--   session_id (string)   – iTerm2 AppleScript session id (== uuid)
-- Returns nil + error message on failure.
function M.get_iterm_ids_applescript()
    local info, err = M.get_iterm_ids()
    if not info then
        return nil, err
    end

    local script = string.format([[
tell application "iTerm2"
    set targetUUID to "%s"
    repeat with w in windows
        set wid to id of w
        repeat with t in tabs of w
            set tid to id of t
            repeat with s in sessions of t
                if unique ID of s is equal to targetUUID then
                    return (wid as string) & "|" & (tid as string) & "|" & (unique ID of s)
                end if
            end repeat
        end repeat
    end repeat
    return "NOT_FOUND"
end tell
]], info.session_uuid)

    local output = vim.fn.system({ "osascript", "-e", script })
    output = output:gsub("%s+$", "") -- trim trailing whitespace/newline

    if vim.v.shell_error ~= 0 or output == "NOT_FOUND" or output == "" then
        return nil, "AppleScript query failed or session not found: " .. (output or "")
    end

    local window_id, tab_id, session_id = output:match("^(.+)|(.+)|(.+)$")
    if not window_id then
        return nil, "Unexpected AppleScript output: " .. output
    end

    return {
        window_id  = window_id,
        tab_id     = tab_id,
        session_id = session_id,
    }
end

-- Convenience: print iTerm2 IDs to the Neovim messages area.
function M.print_iterm_ids()
    local info, err = M.get_iterm_ids()
    if not info then
        vim.notify("[iterm] " .. err, vim.log.levels.ERROR)
        return
    end

    vim.notify(string.format(
        "[iterm] window_idx=%d  tab_idx=%d  pane_idx=%d\n        session_uuid=%s",
        info.window_idx, info.tab_idx, info.pane_idx, info.session_uuid
    ), vim.log.levels.INFO)
end

-- Convenience: print AppleScript-level iTerm2 IDs to the messages area.
function M.print_iterm_ids_applescript()
    local ids, err = M.get_iterm_ids_applescript()
    if not ids then
        vim.notify("[iterm] " .. err, vim.log.levels.ERROR)
        return
    end

    vim.notify(string.format(
        "[iterm] window_id=%s  tab_id=%s  session_id=%s",
        ids.window_id, ids.tab_id, ids.session_id
    ), vim.log.levels.INFO)
end

return M
