
if exists('g:mftag_loaded')
    finish
endif
let g:mftag_loaded = 1
let s:mftag_start_up = 1
let s:mftag_debug = 0

augroup MFtags
    autocmd!
augroup END

"########## variables initializing
if !exists('g:mftag_dir_auto_set')
    let g:mftag_dir_auto_set = 0
endif

if !exists('g:mftag_dir')
    let g:mftag_dir = []
endif

if !exists('g:mftag_save_dir')
    let g:mftag_save_dir = ''
endif

if !exists('g:mftag_exe_option')
    let g:mftag_exe_option = '-R'
endif

if !exists('g:mftag_func_list_name')
    let g:mftag_func_list_name = 'MF_func_list'
endif

if !exists('g:mftag_func_list_width')
    let g:mftag_func_list_width = 40
endif

if !exists('g:mftag_auto_close')
    let g:mftag_auto_close = 0
endif

"########## global settings

let s:file = expand("<sfile>")

if has('win32')
    let s:sep = '\'
else
    let s:sep = '/'
endif

function! s:MFdebug()
    echo "###debug###"
    "echo "@ " . s:file . " " . expand("<sfile>") . " line " . expand("<slnum>")
    echo "@ " . s:file . " " . expand("<sfile>")
endfunction

function! MFset_dir_auto()
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    let l:base_name = [".svn",".git"]

    let l:search_dir = expand('%:p:h')
    while 1
        let l:while_end = 0
        for bn in l:base_name
            let l:base_dir = l:search_dir . s:sep . bn
            if s:mftag_debug == 1
                call s:MFdebug()
                echomsg l:base_dir
            endif
            if isdirectory(l:base_dir)
                if s:mftag_debug == 1
                    echomsg "break"
                endif
                return l:search_dir
            endif
        endfor
        let l:last_sep = strridx(l:search_dir,s:sep)
        if l:last_sep <= 0
            if s:mftag_debug == 1
                call s:MFdebug()
            endif
            return -1
        endif
        let l:search_dir = l:search_dir[:l:last_sep-1]
    endwhile

endfunction

function! MFsearch_dir(dir)
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    if g:mftag_dir_auto_set == 1
        let ret = MFset_dir_auto()
        if ret != -1
            return ret
        endif
    endif

    let l:curdir = expand('%:p:h') . "/"

    for d in a:dir
        let d = '\<' . d . '\>'
        let l:n = matchend(l:curdir,d)
        if l:n != -1
            if s:mftag_debug == 1
                call s:MFdebug()
                echo l:curdir[:l:n]
            endif
            return l:curdir[:l:n]
        endif
    endfor
    if !exists("s:mftag_start_up")
        echo "no match directory"
    endif
    return expand('%:p:h')
endfunction

function! s:set_mftag_save_dir()
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    if g:mftag_save_dir != ''
        let b:mftag_save_dir = g:mftag_save_dir
        if s:mftag_debug == 1
            call s:MFdebug()
            echo "s:set_mftag_save_dir 1"
        endif
    elseif (g:mftag_dir_auto_set==1 || g:mftag_dir!=[])
        let b:mftag_save_dir = MFsearch_dir(g:mftag_dir)
        if s:mftag_debug == 1
            call s:MFdebug()
            echo "s:set_mftag_save_dir 2"
        endif
    else
        let b:mftag_save_dir = getcwd()
        if s:mftag_debug == 1
            call s:MFdebug()
            echo "s:set_mftag_save_dir 3"
        endif
    endif

    if b:mftag_save_dir[strlen(b:mftag_save_dir)-1] != s:sep
        let b:mftag_save_dir = b:mftag_save_dir . s:sep
    endif
endfunction

call s:set_mftag_save_dir()

unlet s:mftag_start_up

"########## tags syntax setting
if !exists('g:mftag_no_need_MFsyntax')
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    function! s:check_and_read_file(ft)
        call s:set_mftag_save_dir()
        let l:filename = b:mftag_save_dir . a:ft . "_tag_syntax.vim"
        if filereadable(l:filename)
            execute "source " . l:filename
        endif
    endfunction
    
    autocmd MFtags FileType python call s:check_and_read_file(&filetype)
    autocmd MFtags FileType c call s:check_and_read_file(&filetype)
    autocmd MFtags FileType cpp call s:check_and_read_file(&filetype)
    autocmd MFtags FileType vim call s:check_and_read_file(&filetype)

    command! MFsyntax :call mftags#make_tag_syntax_file()

endif
"########## execute ctag setting
if !exists('g:mftag_no_need_MFctag')

    "execute ctags command at specified directory
    "specify directory name by setting valiabe 'g:mftag_dir'
    "ex) g:mftag_dir = ['work','top','hoge']
    "   I'm opening file @ /home/to/work/dir/src
    "   => make tags file @ /home/to/work
    "   I'm opening file @ /from/top/dir/to/hoge/project/src
    "   => make tags file @ /from/top/
    "   I'm opening file @ /home/to/work/dir/work/dir/src
    "   => make tags file @ /from/to/work/dir/work
    function! MFexe_ctags(dir)
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
    
        let l:pwd = getcwd()
        let l:exe_dir = MFsearch_dir(a:dir)
        echo l:exe_dir
        if l:exe_dir == ''
            return
        endif
        sleep 2
        execute "cd " . l:exe_dir
        execute "! ctags " . g:mftag_exe_option
    
        execute "cd " . l:pwd
    endfunction
    
    command! MFctag :call MFexe_ctags(g:mftag_dir)

endif

"########## show all functions, variables, etc.. settings
if !exists('g:mftag_no_need_MFfunclist')

    function! MFshow_func_list(kind_char)
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
        let l:file_type = &filetype
        let l:file_path = expand('%:p')
        execute "silent topleft vertical " . g:mftag_func_list_width . "split " . g:mftag_func_list_name
        call s:set_func_list_win()
        call mftags#show_kind_list(l:file_type, l:file_path, a:kind_char)
    endfunction

    function! s:set_func_list_win()
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
        " set up function list window
        setlocal modifiable
        setlocal noreadonly
        setlocal nonumber
        setlocal noswapfile
        setlocal nobackup
        setlocal noundofile
        setlocal filetype=FuncList
        setlocal buftype=nofile
        setlocal nobuflisted
        setlocal nowrap
        setlocal report=9999

        setlocal foldminlines=0
        "setlocal foldlevel=9999
        setlocal foldmethod=indent
        setlocal foldcolumn=3

        nnoremap <buffer> <CR> zO
        nnoremap <buffer> + zR
        nnoremap <buffer> - zC
        nnoremap <buffer> = zM
        command! MFjumpTab :call s:MF_tag_jump('tab')
        nnoremap <silent> <buffer> t :MFjumpTab<CR>
        command! MFjumpWin :call s:MF_tag_jump('win')
        nnoremap <silent> <buffer> w :MFjumpWin<CR>

        nnoremap <silent> <buffer> q :q<CR>

    endfunction

    function! s:MF_tag_jump(type)
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
        let l:cword = getline('.')
        if len(l:cword) < 2
            if s:mftag_debug == 1
                call s:MFdebug()
                echo "[" . l:cword . "]"
                echo "tag jump word is too short!"
            endif
            return
        endif
        if l:cword[1] != '	'
            if s:mftag_debug == 1
                call s:MFdebug()
                echo "[" . l:cword . "]"
                echo "not tag jump word!"
            endif
            return
        endif
        "let l:cword = expand('<cword>')
        echo l:cword
        if a:type == "tab"
            tabnew
        elseif a:type == "win"
            wincmd p
        endif
        execute "tjump " . l:cword
    endfunction

    function! s:MFtag_list_usage(...)
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
        " close if  FuncList is already open.
        let l:winnr = bufwinnr(g:mftag_func_list_name)
        if l:winnr != -1
            execute l:winnr . "wincmd w"
            close
        endif

        "save old value
        let l:old_report = &report
        "check file type
        if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
            echo "not suppourted file type!"
            return
        endif

        let enable_kinds = 'list, all, '
        if &filetype == 'python'
            let enable_kinds .= 'c, f, m, v, i'
        elseif &filetype == 'c'
            let enable_kinds .= 'c, d, e, f, g, l, m, n, p, s, t, u, v, x'
        elseif &filetype == 'cpp'
            let enable_kinds .= 'c, d, e, f, g, l, m, n, p, s, t, u, v, x'
        elseif &filetype == 'vim'
            let enable_kinds .= 'a, c, f, m, v'
        endif

        if a:0 == 0
            if &filetype == 'python'
                let l:args = 'cfmvi'
            elseif &filetype == 'c'
                let l:args = 'cdefglmnpstuvx'
            elseif &filetype == 'cpp'
                let l:args = 'cdefglmnpstuvx'
            elseif &filetype == 'vim'
                let l:args = 'acfmv'
            else
                let l:args = ''
            endif
        else
            if a:1 == 'list'
                echo "selectable arguments are [" . enable_kinds . "]"
            else
                let l:args = a:1
            endif
        endif
        call MFshow_func_list(l:args)

        " return values
        setlocal nomodifiable
        execute "set report=" . l:old_report

    endfunction

    command! -nargs=? MFfunclist :call s:MFtag_list_usage(<f-args>)

    function! s:funclist_ayuto_close()
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
        " check other windows
        if winbufnr(2) == -1
            " check other tab page
            if tabpagenr('$') == 1
                bdelete
                quit
            else
                close
            endif
        endif
    endfunction

    if g:mftag_auto_close == 1
        autocmd MFtags BufEnter MF_func_list nested
                    \ call s:funclist_ayuto_close()
    endif

endif

