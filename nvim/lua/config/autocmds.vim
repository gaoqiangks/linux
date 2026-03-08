function! CommentEmptyLines()
    let save_cursor = getpos(".")
    silent! % s/^\s*$/%/g
    call setpos('.', save_cursor)
endfunction
if exists('g:vscode')
    "autocmd BufWriteCmd *.tex call CommentEmptyLines()
endif
