
if exists('g:loaded_mftags')
    finish
endif
let g:loaded_mftags = 1
let s:mftag_start_up = 1
let s:mftag_debug = 0
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.


augroup MFtags
    autocmd!
augroup END

"########## variables initializing
" {{{
let s:sep = fnamemodify('.', ':p')[-1:]
" also check &shellslash ?

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
else
    if g:mftag_save_dir[-1] != s:sep
        let g:mftag_save_dir .= s:sep
    endif
    let g:mftag_save_dir = expand(g:mftag_save_dir)
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

if !exists('g:mftag_syntax_overwrite')
    let g:mftag_syntax_overwrite = 1
endif

" }}}

"########## global settings
" {{{

let s:file = expand("<sfile>")

function! s:MFdebug( level, str ) abort
    if a:level > s:mftag_debug
        return
    endif
    if a:str == ""
        let db_print = "###debug### " . "@ " . s:file . " " . expand("<sfile>")
    else
        let l:db_print =  "###debug### " . a:str
    endif
    echo l:db_print
endfunction

function! s:MFset_dir_ank() abort
    call s:MFdebug(1, "")
    let l:search_dir = expand('%:p:h')

    while 1
        let l:base_file = l:search_dir . s:sep . g:mftag_ank
        call s:MFdebug(3, l:base_file)
        if filereadable(l:base_file)
            return l:search_dir
        endif
        let l:last_sep = strridx(l:search_dir, s:sep)
        if l:last_sep <= 0
            call s:MFdebug(3, "last_sep : " . l:last_sep)
            return -1
        endif
        let l:search_dir = l:search_dir[:l:last_sep-1]
    endwhile
endfunction


function! s:MFset_dir_auto() abort
    call s:MFdebug(1, "")
    let l:base_name = [".svn",".git"]

    let l:search_dir = expand('%:p:h')
    while 1
        for bn in l:base_name
            let l:base_dir = l:search_dir . s:sep . bn
            call s:MFdebug(3, l:base_dir)
            if isdirectory(l:base_dir)
                call s:MFdebug(2, "break @ " . l:search_dir)
                return l:search_dir
            endif
        endfor
        let l:last_sep = strridx(l:search_dir,s:sep)
        if l:last_sep <= 0
            call s:MFdebug(3, "last_sep : " . l:last_sep)
            return -1
        endif
        let l:search_dir = l:search_dir[:l:last_sep-1]
    endwhile

endfunction

let s:echo_no_dir = 1
function! s:MFset_dir_list(dir) abort
    call s:MFdebug(1, "")
    let l:curdir = expand('%:p:h') . "/"

    for d in a:dir
        let d = '\<' . d . '\>'
        let l:n = matchend(l:curdir,d)
        if l:n != -1
            call s:MFdebug(2, l:curdir[:l:n])
            return l:curdir[:l:n]
        endif
    endfor
    if (!exists("s:mftag_start_up")) && (s:echo_no_dir==1)
        echo "no match directory"
        let s:echo_no_dir = 0
    endif
    return expand('%:p:h')

endfunction


function! MFsearch_dir(dir) abort
    call s:MFdebug(1, "")
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

function! s:set_mftag_save_dir() abort
    call s:MFdebug(1, "")
    if g:mftag_save_dir != ''
        let b:mftag_save_dir = g:mftag_save_dir
        call s:MFdebug(2, "s:set_mftag_save_dir 1")
    elseif (g:mftag_dir_auto_set==1 || g:mftag_dir!=[])
        let b:mftag_save_dir = MFsearch_dir(g:mftag_dir)
        call s:MFdebug(2, "s:set_mftag_save_dir 2")
    else
        let b:mftag_save_dir = getcwd()
        call s:MFdebug(2, "s:set_mftag_save_dir 3")
    endif

    if b:mftag_save_dir[strlen(b:mftag_save_dir)-1] != s:sep
        let b:mftag_save_dir = b:mftag_save_dir . s:sep
    endif
endfunction

function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

call s:set_mftag_save_dir()

unlet s:mftag_start_up
" }}}

"########## tags syntax setting
" {{{
if !exists('g:mftag_no_need_MFsyntax')

    call s:MFdebug(1, "")

    function! s:check_and_read_file(ft) abort
        call s:set_mftag_save_dir()
        let l:filename = b:mftag_save_dir . "." . a:ft . "_tag_syntax.vim"
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
" }}}

"########## execute ctag setting
" {{{
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
    function! MFexe_ctags(dir) abort
        call s:MFdebug(1, "")

        let l:lang_option = ""
        for vs in keys(g:)
            if len(vs) >= 15
                if (vs[:5] == "mftag_") && (vs[-8:]=="_setting")
                    if has_key(g:{vs}, 'tag')
                        let l:ft = vs[6:-9]
                        if l:ft == "cpp"
                            let l:ft = "c++"
                        endif
                        let l:lang_option .= " --" . l:ft . "-kinds=" . g:{vs}['tag']
                    endif
                endif
            endif
        endfor

        let l:cmd_str = "ctags " . g:mftag_exe_option . l:lang_option

        let l:pwd = getcwd()
        let l:exe_dir = MFsearch_dir(a:dir)
        if l:exe_dir == ''
            return
        endif
        execute "cd " . l:exe_dir
        if has("gui_running")
            execute "silent !" . l:cmd_str
        else
            let l:echo_str = "'execute " . l:cmd_str . " @ " . l:exe_dir . "'"
            execute "!echo " . l:echo_str . " && " . l:cmd_str
        endif
        " redraw
        redraw!
        echo "execute '" . l:cmd_str . "' @ " . l:exe_dir
    
        execute "cd " . l:pwd
    endfunction
    
    command! MFctag :call MFexe_ctags(g:mftag_dir)

endif
" }}}

"########## show all functions, variables, etc.. settings
" {{{
if !exists('g:mftag_no_need_MFfunclist')

    function! MFshow_func_list(file_types) abort
        call s:MFdebug(1, "")
        let l:tag_files = tagfiles()
        let l:file_path = expand('%:p')

        " set kinds
        let l:file_types = split(a:file_types, ',')
        let l:kinds = []
        for l:ft in l:file_types
            "check file type
            if (l:ft != 'c') && (l:ft != 'cpp') && (l:ft != 'python') && (l:ft != 'vim')
                echo l:ft . " is not a suppourted file type!"
                continue
            endif
            if exists("g:mftag_" . l:ft . "_setting")
                if has_key(g:mftag_{l:ft}_setting, 'func')
                    let l:kinds += [g:mftag_{l:ft}_setting['func']]
                elseif has_key(g:mftag_{l:ft}_setting, 'tag')
                    let l:kinds += [g:mftag_{l:ft}_setting['tag']]
                endif
                call s:MFdebug(2, l:ft . " read kinds from setting::" . l:kinds[-1])
            elseif l:ft == 'python'
                let l:kinds += ['cfmvi']
            elseif l:ft == 'c'
                let l:kinds += ['cdefglmnpstuvx']
            elseif l:ft == 'cpp'
                let l:kinds += ['cdefglmnpstuvx']
            elseif l:ft == 'vim'
                let l:kinds += ['acfmv']
            else
                let l:kinds += ['']
            endif
            call s:MFdebug(2, l:ft . " set kinds::" . l:kinds[-1])
        endfor
        if len(l:kinds) == 0
            call s:MFdebug(1, 'len(kinds) == 0;')
            return
        endif

        if exists('g:mftag_popup_on') && g:mftag_popup_on != 0
            call mftags#show_kind_list(l:file_types, l:file_path, l:kinds, l:tag_files)
            if len(sort(keys(g:tmp_dic_pop))) == 0
                echo 'no contents'
                unlet g:tmp_dic_pop
                return
            endif
            call popup_menu(sort(keys(g:tmp_dic_pop)), #{
                        \ callback : s:SID_PREFIX().'select_ft_popCB',
                        \ maxheight : &lines-7,
                        \ close : 'button',
                        \ mapping : 1,
                        \})
        else
            execute "silent topleft vertical " . g:mftag_func_list_width . "split " . g:mftag_func_list_name
            call s:set_func_list_win()
            call mftags#show_kind_list(l:file_types, l:file_path, l:kinds, l:tag_files)
            setlocal nomodifiable
        endif
    endfunction

    function! MFfold_lev(lnum)
        let l:line = getline(a:lnum)
        " if l:line == ''
        "     return 0
        " endif

        " if l:line[:2] == '---'
        "     echo l:line[:2]
        "     return 1
        " endif

        let l:cnt = 0
        for i in range(len(l:line))
            if l:line[i] == "\t"
                let l:cnt += 1
            endif
        endfor
        return l:cnt
    endfunction

    function! s:set_func_list_win() abort
        call s:MFdebug(1, "")
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
        setlocal winfixwidth
        setlocal nolist

        setlocal foldminlines=0
        "setlocal foldlevel=9999
        setlocal foldmethod=expr
        setlocal foldexpr=MFfold_lev(v:lnum)
        setlocal foldcolumn=3

        """ mapping
        nnoremap <silent> <buffer> +              :call <SID>MF_tag_map("+")<CR>
        nnoremap <silent> <buffer> -              :call <SID>MF_tag_map("-")<CR>
        nnoremap <silent> <buffer> =              :call <SID>MF_tag_map("=")<CR>
        nnoremap <silent> <buffer> <c-t>          :call <SID>MF_tag_jump('tab')<CR>
        nnoremap <silent> <buffer> <c-p>          :call <SID>MF_tag_jump('preview')<CR>
        nnoremap <silent> <buffer> <CR>           :call <SID>MF_tag_map("enter")<CR>
        nnoremap <silent> <buffer> <space><space> :call <SID>MF_tag_map("space2")<CR>

        nnoremap <silent> <buffer> q              :call <SID>MF_tag_map("q")<CR>

    endfunction

    function! <SID>get_ft_kind() abort
        for l:ln in getline(1, '.')
            if l:ln !~ "\t\t"
                let l:kind = substitute(l:ln, '\t', '', '')
            endif
            if l:ln[:2] == '---'
                let l:ft = l:ln[3:-4]
            endif
        endfor
        return [l:ft, l:kind]
    endfunction

    function! <SID>MF_tag_map(args) abort
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
                call <SID>MF_tag_jump('win')
            endif
        elseif a:args == "space2"
            if foldclosed(line('.')) == -1
                let l:tmp_res = <SID>get_ft_kind()
                let l:ft = l:tmp_res[0]
                let l:kind = l:tmp_res[1]
                unlet l:tmp_res
                call mftags#show_def(l:ft, l:kind, getline('.'))
            endif
        elseif a:args == "q"
            quit
        endif
    endfunction

    function! <SID>MF_tag_jump(type) abort
        call s:MFdebug(1, "")
        let l:cword = getline('.')
        let l:tmp_res = <SID>get_ft_kind()
        let l:ft = l:tmp_res[0]
        let l:kind = l:tmp_res[1]
        unlet l:tmp_res
        if l:kind == ''
            call s:MFdebug(1, 'no kind found.')
            return
        endif

        if len(l:cword) < 2
            call s:MFdebug(2, "[" . l:cword . "]  " . "tag jump word is too short!")
            return
        endif
        if l:cword[1] != '	'
            call s:MFdebug(2, "[" . l:cword . "]  " . "not tag jump word!" )
            return
        endif
        "let l:cword = expand('<cword>')
        if a:type == "tab"
            let l:win_info = win_id2tabwin(win_getid())
            tabnew
            call mftags#tag_jump(l:ft, l:kind, l:cword)
            if expand("%:t") == ""
                quit
                execute l:win_info[0] . "tabnext"
                execute l:win_info[1] . 'wincmd w'
            endif
        elseif a:type == "win"
            wincmd p
            call mftags#tag_jump(l:ft, l:kind, l:cword)
        elseif a:type == "preview"
            let l:win_info = win_id2tabwin(win_getid())
            execute "silent " . &previewheight . "new"
            call mftags#tag_jump(l:ft, l:kind, l:cword)
            setlocal previewwindow
            if expand("%:t") == ""
                quit
                execute l:win_info[0] . "tabnext"
                execute l:win_info[1] . 'wincmd w'
            endif
        endif
    endfunction

    function! <SID>select_ft_popCB(id, res)
        call s:MFdebug(2, 'ft:res' . a:res . '---')
        " not selected
        if a:res <= 0
            unlet g:tmp_dic_pop
            return
        endif

        let ft = sort(keys(g:tmp_dic_pop))[a:res-1]
        call <SID>select_kind_pop(ft)
    endfunction

    function! <SID>select_kind_pop(ft)
        call popup_clear()
        let w:ft = a:ft
        let w:kinds = sort(keys(g:tmp_dic_pop[a:ft]))
        if len(w:kinds) == 0
            echo 'no contents'
            unlet g:tmp_dic_pop
            return
        endif
        call popup_menu(w:kinds, #{
                    \ callback : s:SID_PREFIX().'select_kind_popCB',
                    \ maxheight : &lines-7,
                    \ close : 'button',
                    \ mapping : 1,
                    \})
    endfunction

    function! <SID>select_kind_popCB(id, res)
        call s:MFdebug(2, 'kind:res' . a:res . '---')
        " not selected
        if a:res <= 0
            unlet g:tmp_dic_pop
            return
        endif

        let kind = sort(keys(g:tmp_dic_pop[w:ft]))[a:res-1]
        call <SID>select_func_pop(w:ft, kind)
    endfunction

    function! <SID>select_func_pop(ft, kind)
        call popup_clear()
        let w:funcs = g:tmp_dic_pop[a:ft][a:kind]
        let w:ft = a:ft
        let w:kind = a:kind
        if len(w:funcs) == 0
            echo 'no contents'
            unlet g:tmp_dic_pop
            return
        endif
        call popup_menu(w:funcs, #{
                    \ callback : s:SID_PREFIX().'select_func_popCB',
                    \ maxheight : &lines-7,
                    \ close : 'button',
                    \ mapping : 1,
                    \ })
    endfunction

    function! <SID>select_func_popCB(id, res)
        call s:MFdebug(2, 'func:res' . a:res . '---')
        " not selected
        if a:res <= 0
            unlet g:tmp_dic_pop
            return
        endif

        " deleted below vars when win_getid?
        let l:ft = w:ft
        let l:kind = w:kind
        let l:funcs = w:funcs

        let l:win_info = win_id2tabwin(win_getid())
        tabnew
        call mftags#tag_jump(l:ft, l:kind, "\t\t".l:funcs[a:res-1])
        if exists('g:tmp_dic')
            call s:MFdebug(1, 'g:tmp_dic exists')
            call <SID>select_file_pop(l:win_info)
        else
            if expand("%:t") == ""
                quit
                execute l:win_info[0] . "tabnext"
                execute l:win_info[1] . 'wincmd w'
            endif
        endif

        unlet g:tmp_dic_pop
    endfunction

    function! <SID>select_file_pop(win_info)
        call popup_clear()
        let w:old_win_info = a:win_info
        let ret = []
        for i in keys(g:tmp_dic)
            let add_str = '  ' . i . ' ' . g:tmp_dic[i][0] . ' : ' . g:tmp_dic[i][1] . ' lines'
            call add(ret, add_str)
        endfor
        if len(ret) == 0
            echo 'no contents'
            unlet g:tmp_dic_pop
            return
        endif
        call popup_menu(ret, #{
                    \ callback : s:SID_PREFIX().'select_file_popCB',
                    \ maxheight : &lines-7,
                    \ close : 'button',
                    \ mapping : 1,
                    \ })
    endfunction

    function! <SID>select_file_popCB(id, res)
        let l:ind = a:res-1
        if l:ind >= 0
            call s:MFdebug(2, "open " . g:tmp_dic[l:ind][0] . "::" . g:tmp_dic[l:ind][1])
            execute "silent e +" . g:tmp_dic[l:ind][1] . " " . g:tmp_dic[l:ind][0]
        else
            call s:MFdebug(1, 'a:res:' . a:res . '-- less than 1. error.')
        endif
        let l:win_info = w:old_win_info

        if expand("%:t") == ""
            quit
            execute l:win_info[0] . "tabnext"
            execute l:win_info[1] . 'wincmd w'
        endif
        unlet g:tmp_dic
    endfunction

    function! s:echo_mftag_usage(file_types) abort
        let l:echo_list = ''
        if a:file_types == ''
            let l:echo_list .= "usage; :MFfunclist [<filetype>] [help]\n"
            let l:echo_list .= "       :MFfunclist del\n"
            let l:echo_list .= "help\t\t: show this usage and close.\n"
            let l:echo_list .= "<ft> help\t: show enable kinds for the filetype and close.\n"
            let l:echo_list .= "del\t\t: delete buffer.\n"
            let l:echo_list .= "suppourted languages: python, c, cpp, vim"
            return l:echo_list
        endif
        for ft in split(a:file_types, ',')
            if ft == 'python'
                let l:echo_list .= "---" . ft . "---\n"
                let l:echo_list .= "c \t\t: classes\n"
                let l:echo_list .= "f \t\t: functions\n"
                let l:echo_list .= "m \t\t: class members\n"
                let l:echo_list .= "v \t\t: variables\n"
                let l:echo_list .= "i \t\t: imports\n"
            elseif ft == 'c'
                let l:echo_list .= "---" . ft . "---\n"
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
            elseif ft == 'cpp'
                let l:echo_list .= "---" . ft . "---\n"
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
            elseif ft == 'vim'
                let l:echo_list .= "---" . ft . "---\n"
                let l:echo_list .= "a \t\t: autocommand groups\n"
                let l:echo_list .= "c \t\t: user-defined commands\n"
                let l:echo_list .= "f \t\t: function definitions\n"
                let l:echo_list .= "m \t\t: maps\n"
                let l:echo_list .= "v \t\t: variable definitions\n"
            endif
        endfor

        return l:echo_list
    endfunction

    function! s:MFtag_chk_open() abort
        for i in range(1, tabpagenr('$'))
            let bufnrs = tabpagebuflist(i)
            for j in bufnrs
                if bufname(j) == g:mftag_func_list_name
                    echo 'Function list is already opened. -> tab=' . i . ', win=' . j
                    return 1
                endif
            endfor
        endfor
        return 0
    endfunction
    function! s:MFtag_list_usage(...) abort
        call s:MFdebug(1, "")
        " close if  FuncList is already open.
        let l:winnr = bufwinnr(g:mftag_func_list_name)
        if l:winnr != -1
            execute l:winnr . "wincmd w"
            close
        endif

        if s:MFtag_chk_open() == 1
            return
        endif

        "save old value
        let l:old_report = &report

        if a:0 == 0
            let l:ft = &filetype
        else
            let l:tmp_list = split(a:1)
            if (len(l:tmp_list) > 1) && (l:tmp_list[1] == 'help')
                echo s:echo_mftag_usage(l:tmp_list[0])
                return
            elseif a:1 == 'help'
                echo s:echo_mftag_usage('')
                return
            elseif a:1 == 'del'
                call mftags#delete_buffer()
                return
            else
                let l:ft = a:1
            endif
        endif
        if tagfiles() == []
            echo "Tag file is not found."
            return
        endif

        call MFshow_func_list(l:ft)

        " return values
        execute "set report=" . l:old_report

    endfunction

    command! -nargs=? MFfunclist :call s:MFtag_list_usage(<f-args>)

    function! s:funclist_auto_close() abort
        call s:MFdebug(1, "")
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
                    \ call s:funclist_auto_close()
    endif

endif
" }}}

