if !exists('g:mftag_log')
    let g:mftag_log = ''
endif

function! MF_move_buf() abort
    let df_exist = 0
    for bn in tabpagebuflist()
        if bufname(bn) == 'MFtagDebug'
            let wids = win_findbuf(bn)
            call win_gotoid(wids[0])
            let df_exist = 1
        endif
    endfor

    if df_exist == 0
        vertical split MFtagDebug
        setlocal noswapfile
        setlocal nobackup
        setlocal noundofile
        setlocal buftype=nofile
        setlocal nobuflisted
        setlocal nofoldenable
    endif
endfunction

function! MFtagDebug(str, src, fname) abort
    if a:str == ""
        let l:db_print = "###debug-".a:src."### " . "@ " . a:fname . " " . expand("<sfile>")
    else
        let l:db_print =  "###debug-".a:src."### " . a:str
    endif

    let g:mftag_log .= l:db_print."\n"
    call MF_move_buf()

    1,$delete _
    silent put =g:mftag_log
    1,1delete _
    wincmd p
endfunction


