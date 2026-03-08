function LogOutput(msg)
	let l:logfile = expand('/home/gaoqiang/nvim.log')
	let l:time = strftime('%Y-%m-%d %H:%M:%S')
	let l:msg = a:msg
	call writefile([l:time . ' ' . l:msg], l:logfile, 'a')
	call writefile(["filetype = " . &filetype], l:logfile, 'a')
endfunction

"let events=["BufWriteCmd", "BufWritePost"]
let events=["BufAdd", "BufDelete", "BufEnter", "BufFilePost", "BufFilePre", "BufHidden", "BufLeave", "BufModifiedSet", "BufNew", "BufNewFile", "BufRead", "BufReadCmd", "BufUnload", "BufWinEnter", "BufWinLeave", "BufWipeout", "BufWrite", "BufWriteCmd", "BufWritePost", "ChanInfo", "ChanOpen", "CmdUndefined", "CmdlineChanged", "CmdlineEnter", "CmdlineLeave", "CmdwinEnter", "CmdwinLeave", "ColorScheme", "ColorSchemePre", "CompleteChanged", "CompleteDonePre", "CompleteDone", "CursorHold", "CursorHoldI", "CursorMoved", "CursorMovedI", "DiffUpdated", "DirChanged", "DirChangedPre", "ExitPre", "FileAppendCmd", "FileAppendPost", "FileAppendPre", "FileChangedRO", "FileChangedShell", "FocusGained", "FileChangedShellPost", "FileReadCmd", "FileReadPost", "FileReadPre", "FileType", "FileWriteCmd", "FileWritePost", "FileWritePre", "FilterReadPost", "FilterReadPre", "FilterWritePost", "FilterWritePre", "FocusGained", "FocusLost", "FuncUndefined", "UIEnter", "UILeave", "InsertChange", "InsertCharPre", "InsertEnter", "InsertLeavePre", "InsertLeave", "MenuPopup", "ModeChanged", "OptionSet", "QuickFixCmdPre", "QuickFixCmdPost", "QuitPre", "RemoteReply", "SearchWrapped", "RecordingEnter", "RecordingLeave", "SafeState", "SessionLoadPost", "SessionWritePost", "ShellCmdPost", "Signal", "ShellFilterPost", "SourcePre", "SourcePost", "SourceCmd", "SpellFileMissing", "StdinReadPost", "StdinReadPre", "SwapExists", "Syntax", "TabEnter", "TabLeave", "TabNew", "TabNewEntered", "TabClosed", "TermOpen", "TermEnter", "TermLeave", "TermClose", "TermRequest", "TermResponse", "TextChanged", "TextChangedI", "TextChangedP", "TextChangedT", "TextYankPost", "User", "VimEnter", "VimLeave", "VimLeavePre", "VimResized", "VimResume", "VimSuspend", "WinClosed", "WinEnter", "WinLeave", "WinNew", "WinScrolled", "WinResized"]
autocmd!
for event in events
    exe printf('au %s * call LogOutput("%s")', event, event)
endfor

