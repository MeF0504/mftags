
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
if !exists('g:mftag_ank')
    let g:mftag_ank = ".mfank"
endif

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

function! s:MFset_dir_ank()
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    let l:search_dir = expand('%:p:h')

    while 1
        let l:base_file = l:search_dir . s:sep . g:mftag_ank
        if s:mftag_debug == 1
            echo l:base_file
        endif
        if filereadable(l:base_file)
            return l:search_dir
        endif
        let l:last_sep = strridx(l:search_dir, s:sep)
        if l:last_sep <= 0
            if s:mftag_debug == 1
                echo "last_sep : " . l:last_sep
            endif
            return -1
        endif
        let l:search_dir = l:search_dir[:l:last_sep-1]
    endwhile
endfunction


function! s:MFset_dir_auto()
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    let l:base_name = [".svn",".git"]

    let l:search_dir = expand('%:p:h')
    while 1
        for bn in l:base_name
            let l:base_dir = l:search_dir . s:sep . bn
            if s:mftag_debug == 1
                echo l:base_dir
            endif
            if isdirectory(l:base_dir)
                if s:mftag_debug == 1
                    echo "break"
                endif
                return l:search_dir
            endif
        endfor
        let l:last_sep = strridx(l:search_dir,s:sep)
        if l:last_sep <= 0
            if s:mftag_debug == 1
                echo "last_sep : " . l:last_sep
            endif
            return -1
        endif
        let l:search_dir = l:search_dir[:l:last_sep-1]
    endwhile

endfunction

function! s:MFset_dir_list(dir)
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    let l:curdir = expand('%:p:h') . "/"

    for d in a:dir
        let d = '\<' . d . '\>'
        let l:n = matchend(l:curdir,d)
        if l:n != -1
            if s:mftag_debug == 1
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


function! MFsearch_dir(dir)
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    let ret = s:MFset_dir_ank()
    if ret != -1
        return ret
    endif

    if g:mftag_dir_auto_set == 1
        let ret = s:MFset_dir_auto()
        if ret != -1
            return ret
        endif
    endif

    let ret = s:MFset_dir_list(a:dir)
    return ret

endfunction

function! s:set_mftag_save_dir()
    if s:mftag_debug == 1
        call s:MFdebug()
    endif
    if g:mftag_save_dir != ''
        let b:mftag_save_dir = g:mftag_save_dir
        if s:mftag_debug == 1
            echo "s:set_mftag_save_dir 1"
        endif
    elseif (g:mftag_dir_auto_set==1 || g:mftag_dir!=[])
        let b:mftag_save_dir = MFsearch_dir(g:mftag_dir)
        if s:mftag_debug == 1
            echo "s:set_mftag_save_dir 2"
        endif
    else
        let b:mftag_save_dir = getcwd()
        if s:mftag_debug == 1
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

        """ mapping
        command! MFjumpTab call s:MF_tag_jump('tab')
        command! MFjumpWin call s:MF_tag_jump('win')
        command! MFjumpPlu call s:MF_tag_map("+")
        command! MFjumpMin call s:MF_tag_map("-")
        command! MFjumpEq  call s:MF_tag_map("=")
        command! MFjumpEn  call s:MF_tag_map("enter")
        command! MFjumpSp2 call s:MF_tag_map("space2")
        command! MFjumpQ   call s:MF_tag_map("q")
        nnoremap <silent> <buffer> +     :MFjumpPlu<CR>
        nnoremap <silent> <buffer> -     :MFjumpMin<CR>
        nnoremap <silent> <buffer> =     :MFjumpEq<CR>
        nnoremap <silent> <buffer> t     :MFjumpTab<CR>
        nnoremap <silent> <buffer> <c-t> :MFjumpTab<CR>
        nnoremap <silent> <buffer> w     :MFjumpWin<CR>
        nnoremap <silent> <buffer> <CR>  :MFjumpEn<CR>
        nnoremap <silent> <buffer> <space><space> :MFjumpSp2<CR>

        nnoremap <silent> <buffer> q     :MFjumpQ<CR>

    endfunction

    function! s:MF_tag_map(args)
        if a:args == "+"
            normal! zR
        elseif a:args == "-"
            if expand("<cword>") != ""
                normal! zC
            endif
        elseif a:args == "="
            normal! zM
        elseif a:args == "enter"
            if foldclosed(line('.')) != -1
                normal! zO
            else
                MFjumpWin
            endif
        elseif a:args == "space2"
            if !foldclosed(line('.')) == -1
                echo expand('<cword>')
            endif
        elseif a:args == "q"
            quit
        endif
    endfunction

    function! s:MF_tag_jump(type)
        if s:mftag_debug == 1
            call s:MFdebug()
        endif
        let l:cword = getline('.')
        if len(l:cword) < 2
            if s:mftag_debug == 1
                echo "[" . l:cword . "]"
                echo "tag jump word is too short!"
            endif
            return
        endif
        if l:cword[1] != '	'
            if s:mftag_debug == 1
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

        let l:echo_list = ''
        let l:echo_list .= "help or list \t: show enable characters and close.\n"
        let l:echo_list .= "all\t\t: open MF func list w/ all kinds.\n"
        if &filetype == 'python'
            let l:echo_list .= "c \t\t: classes\n"
            let l:echo_list .= "f \t\t: functions\n"
            let l:echo_list .= "m \t\t: class members\n"
            let l:echo_list .= "v \t\t: variables\n"
            let l:echo_list .= "i \t\t: imports\n"
        elseif &filetype == 'c'
            let l:echo_list .= "c \t\t: classes\n"
            let l:echo_list .= "d \t\t: macro definitions\n"
            let l:echo_list .= "e \t\t: enumerators (values inside an enumeration)\n"
            let l:echo_list .= "f \t\t: function definitions\n"
            let l:echo_list .= "g \t\t: enumeration names\n"
            let l:echo_list .= "l \t\t: local variables\n"
            let l:echo_list .= "m \t\t: class, struct, and union members\n"
            let l:echo_list .= "n \t\t: namespaces\n"
            let l:echo_list .= "p \t\t: function prototypes\n"
            let l:echo_list .= "s \t\t: structure names\n"
            let l:echo_list .= "t \t\t: typedefs\n"
            let l:echo_list .= "u \t\t: union names\n"
            let l:echo_list .= "v \t\t: variable definitions\n"
            let l:echo_list .= "x \t\t: external and forward variable declarations\n"
        elseif &filetype == 'cpp'
            let l:echo_list .= "c \t\t: classes\n"
            let l:echo_list .= "d \t\t: macro definitions\n"
            let l:echo_list .= "e \t\t: enumerators (values inside an enumeration)\n"
            let l:echo_list .= "f \t\t: function definitions\n"
            let l:echo_list .= "g \t\t: enumeration names\n"
            let l:echo_list .= "l \t\t: local variables\n"
            let l:echo_list .= "m \t\t: class, struct, and union members\n"
            let l:echo_list .= "n \t\t: namespaces\n"
            let l:echo_list .= "p \t\t: function prototypes\n"
            let l:echo_list .= "s \t\t: structure names\n"
            let l:echo_list .= "t \t\t: typedefs\n"
            let l:echo_list .= "u \t\t: union names\n"
            let l:echo_list .= "v \t\t: variable definitions\n"
            let l:echo_list .= "x \t\t: external and forward variable declarations\n"
        elseif &filetype == 'vim'
            let l:echo_list .= "a \t\t: autocommand groups\n"
            let l:echo_list .= "c \t\t: user-defined commands\n"
            let l:echo_list .= "f \t\t: function definitions\n"
            let l:echo_list .= "m \t\t: maps\n"
            let l:echo_list .= "v \t\t: variable definitions\n"
        endif
        let l:echo_list .= "characters except 'help', 'list' and 'all' are able to use at once"

        if a:0 == 0
            if exists("g:mftag_" . &filetype . "_default")
                if s:mftag_debug == 1
                    execute 'echo "read default:: " . g:mftag_' . &filetype . '_default'
                endif
                execute "let l:args = g:mftag_" . &filetype . "_default"
            elseif &filetype == 'python'
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
            if (a:1 == 'list') || (a:1 == 'help')
                echo l:echo_list
                return
            elseif a:1 == 'all'
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

