
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

let g:mftag_ank = get(g:, 'mftag_ank', ".mfank")

let g:mftag_dir_auto_set = get(g:, 'mftag_dir_auto_set', 0)

let g:mftag_dir = get(g:, 'mftag_dir', [])

if !exists('g:mftag_save_dir')
    let g:mftag_save_dir = ''
else
    if g:mftag_save_dir[-1] != s:sep
        let g:mftag_save_dir .= s:sep
    endif
    let g:mftag_save_dir = expand(g:mftag_save_dir)
endif

let g:mftag_exe_option = get(g:, 'mftag_exe_option', '-R')

let g:mftag_func_list_name = get(g:, 'mftag_func_list_name', 'MF_func_list')

let g:mftag_func_list_width = get(g:, 'mftag_func_list_width', 40)

let g:mftag_auto_close = get(g:, 'mftag_auto_close', 0)

let g:mftag_syntax_overwrite = get(g:, 'mftag_syntax_overwrite', 1)

let g:mftag_lang_setting = get(g:, 'mftag_lang_setting', {})

" }}}

"########## global settings
" {{{

if s:mftag_debug > 0
    let s:file = expand("<sfile>")
    source <sfile>:h:h/autoload/mftags/src/vim/debug.vim
endif

function! s:MFdebug( level, str ) abort
    if a:level <= s:mftag_debug
        call MFtagDebug(a:str, 'plug-'.a:level, s:file)
    endif
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
    autocmd MFtags FileType sh call s:check_and_read_file(&filetype)

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
        for ft in keys(g:mftag_lang_setting)
            if has_key(g:mftag_lang_setting[ft], 'tag')
                if ft == 'cpp'
                    let ctag_ft = 'c++'
                else
                    let ctag_ft = ft
                endif
                let l:lang_option .= ' --' . ctag_ft . "-kinds=" . g:mftag_lang_setting[ft]['tag']
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
        echomsg "execute '" . l:cmd_str . "' @ " . l:exe_dir

        execute "cd " . l:pwd
    endfunction

    command! MFctag :call MFexe_ctags(g:mftag_dir)

endif
" }}}

"########## show all functions, variables, etc.. settings
" {{{
if !exists('g:mftag_no_need_MFfunclist')

    let s:help_opened = 0

    function! MFshow_func_list(file_types) abort
        call s:MFdebug(1, "")
        let l:tag_files = tagfiles()
        let l:file_path = expand('%:p')

        " set kinds
        let l:file_types = []
        let l:kinds = []
        let def_en_kinds = mftags#get_def_en_kinds()
        for l:ft in keys(a:file_types)
            if match(keys(def_en_kinds), '^'.l:ft.'$') == -1
                echo l:ft . " is not a suppourted file type!"
                continue
            endif

            let l:file_types += [l:ft]
            if a:file_types[l:ft] != ''
                " set kinds from input
                " 重複を削除
                let tmp_kind_list = split(tolower(a:file_types[l:ft]), '\zs')
                let l:kinds += [join(uniq(sort(tmp_kind_list)), '')]
                call s:MFdebug(2, l:ft . " set kinds from input::" . l:kinds[-1])
            elseif has_key(g:mftag_lang_setting, l:ft) &&
                        \ (has_key(g:mftag_lang_setting[l:ft], 'func') ||
                        \ has_key(g:mftag_lang_setting[l:ft], 'tag'))
                " set kinds from global settings
                if has_key(g:mftag_lang_setting[l:ft], 'func')
                    let l:kinds += [g:mftag_lang_setting[l:ft]['func']]
                elseif has_key(g:mftag_lang_setting[l:ft], 'tag')
                    let l:kinds += [g:mftag_lang_setting[l:ft]['tag']]
                else
                    let l:kinds += ['']
                endif
                call s:MFdebug(2, l:ft . " read kinds from setting::" . l:kinds[-1])
            " set kinds from default values
            elseif match(keys(def_en_kinds), '^'.l:ft.'$') != -1
                let l:kinds += [def_en_kinds[l:ft]]
            else
                let l:kinds += ['']
            endif
            call s:MFdebug(2, l:ft . " set kinds::" . l:kinds[-1])
        endfor
        if len(l:kinds) == 0
            call s:MFdebug(1, 'len(kinds) == 0;')
            return
        endif

        if exists('g:mftag_popup_on') && g:mftag_popup_on != 0 && exists('*popup_menu')
            call mftags#show_kind_list(l:file_types, l:file_path, l:kinds, l:tag_files)
            if len(sort(keys(g:tmp_dic_pop))) == 0
                echo 'no contents'
                unlet g:tmp_dic_pop
                return
            endif
            let contents = sort(keys(g:tmp_dic_pop))
            call popup_menu(contents, {
                        \ 'callback' : s:SID_PREFIX().'select_ft_popCB',
                        \ 'maxheight' : &lines-7,
                        \ 'close' : 'button',
                        \ 'mapping' : 0,
                        \ 'filter' : function(s:SID_PREFIX().'popup_my_filter'),
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
        nnoremap <silent> <buffer> ?              :call <SID>MF_tag_map("?")<CR>
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
            if foldlevel('.') != 0
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
        elseif a:args == '?'
            call <SID>MF_tag_show_help()
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
            pclose
            let l:win_info = win_id2tabwin(win_getid())
            execute "topleft silent " . &previewheight . "new"
            call mftags#tag_jump(l:ft, l:kind, l:cword)
            setlocal previewwindow
            if expand("%:t") == ""
                quit
                execute l:win_info[0] . "tabnext"
                execute l:win_info[1] . 'wincmd w'
            endif
        endif
    endfunction

    function! <SID>MF_tag_show_help()
        call s:MFdebug(1, "")
        let help_str =  ['<enter> : open fold under cursor / open the definition in current window']
        let help_str += ['   +    : open all folds']
        let help_str += ['   -    : close fold unser corsor']
        let help_str += ['   =    : close all folds']
        let help_str += [' <c-t>  : open the definition in new tab']
        let help_str += [' <c-p>  : open the definition in preview window']
        let help_str += ['<space><space> : display the definition detail']
        let help_str += ['   ?    : open/close help window']
        let help_str += ['   q    : close tag window']

        "save old value
        let l:old_report = &report
        setlocal modifiable
        setlocal report=9999
        if s:help_opened == 1
            execute "1,".len(help_str)." delete _"
            let s:help_opened = 0
        else
            for i in range(len(help_str))
                call append(i, help_str[i])
            endfor
            let s:help_opened = 1
        endif
        setlocal nomodifiable
        execute "set report=" . l:old_report
    endfunction

    function! <SID>popup_my_filter(id, key)
        " :h popup_menu-shortcut-example
        if a:key ==# 'q'
            return popup_filter_menu(a:id, 'x')
        elseif a:key ==# "\<c-d>"
            call win_execute(a:id, "normal! 5j")
        elseif a:key ==# "\<c-u>"
            call win_execute(a:id, "normal! 5k")
        elseif a:key ==# 'g'
            call win_execute(a:id, "normal! gg")
        elseif a:key ==# 'G'
            call win_execute(a:id, "normal! G")
        endif

        " No shortcut, pass to generic filter
        return popup_filter_menu(a:id, a:key)

    endfunction

    function! <SID>popup_open_file_filter(id, key)
        call win_execute(a:id, "let line = line('.')")
        if a:key ==# "\<c-t>"
            let w:type = 'tab'
            call popup_close(a:id, line)
            return v:true
        elseif a:key ==# "\<c-p>"
            let w:type = 'preview'
            call popup_close(a:id, line)
            return v:true
        elseif a:key ==# "\<CR>"
            let w:type = 'win'
            call popup_close(a:id, line)
            return v:true
        endif

        return <SID>popup_my_filter(a:id, a:key)
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
        " call popup_clear()
        let w:ft = a:ft
        let w:kinds = sort(keys(g:tmp_dic_pop[a:ft]))
        if len(w:kinds) == 0
            echo 'no contents'
            unlet g:tmp_dic_pop
            return
        endif

        call popup_menu(w:kinds, {
                    \ 'callback' : s:SID_PREFIX().'select_kind_popCB',
                    \ 'maxheight' : &lines-7,
                    \ 'close' : 'button',
                    \ 'mapping' : 0,
                    \ 'filter' : function(s:SID_PREFIX().'popup_my_filter'),
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
        " call popup_clear()
        let w:funcs = g:tmp_dic_pop[a:ft][a:kind]
        let w:ft = a:ft
        let w:kind = a:kind
        if len(w:funcs) == 0
            echo 'no contents'
            unlet g:tmp_dic_pop
            return
        endif

        call popup_menu(w:funcs, {
                    \ 'callback' : s:SID_PREFIX().'select_func_popCB',
                    \ 'maxheight' : &lines-7,
                    \ 'close' : 'button',
                    \ 'mapping' : 0,
                    \ 'filter' : function(s:SID_PREFIX().'popup_open_file_filter'),
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

        call s:MFdebug(2, "open func: ".l:ft.", ".l:kind.", ".l:funcs[a:res-1].", ".w:type)

        if w:type == 'tab'
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
        elseif w:type == 'win'
            let l:win_info = win_id2tabwin(win_getid())
            call mftags#tag_jump(l:ft, l:kind, "\t\t".l:funcs[a:res-1])
            if exists('g:tmp_dic')
                call s:MFdebug(1, 'g:tmp_dic exists')
                call <SID>select_file_pop(l:win_info)
            endif
        elseif w:type == 'preview'
            pclose
            let l:win_info = win_id2tabwin(win_getid())
            execute "topleft silent " . &previewheight . "new"
            call mftags#tag_jump(l:ft, l:kind, "\t\t".l:funcs[a:res-1])
            setlocal previewwindow
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
        endif

        unlet g:tmp_dic_pop
    endfunction

    function! <SID>select_file_pop(win_info)
        " call popup_clear()
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

        call popup_menu(ret, {
                    \ 'callback' : s:SID_PREFIX().'select_file_popCB',
                    \ 'maxheight' : &lines-7,
                    \ 'close' : 'button',
                    \ 'mapping' : 0,
                    \ 'filter' : function(s:SID_PREFIX().'popup_my_filter'),
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
        let def_en_kinds = mftags#get_def_en_kinds()
        let l:echo_list = ''
        if a:file_types == ''
            let l:echo_list .= "usage; :MFfunclist [<filetype>[-<kinds>] [<ft>[-<kinds>]]...] [help]\n"
            let l:echo_list .= "       :MFfunclist del\n"
            let l:echo_list .= "help\t\t: show this usage and close.\n"
            let l:echo_list .= "<ft> help\t: show enable kinds for the filetype and close.\n"
            let l:echo_list .= "del\t\t: delete buffer.\n"
            let l:echo_list .= "<ft>-<kinds>\t: open function list for specified filetype.\n"
            let l:echo_list .= "\t\t\t e.g. :MFfunclist c-dfg vim\n"
            let l:echo_list .= "suppourted languages: ".join(sort(keys(def_en_kinds)), ', ')
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
            elseif ft == 'sh'
                let l:echo_list .= "---" . ft . "---\n"
                let l:echo_list .= "f \t\t: functions"
            endif
        endfor

        return l:echo_list
    endfunction

    function! s:MFtag_chk_open() abort
        for i in range(1, tabpagenr('$'))
            let bufnrs = tabpagebuflist(i)
            for j in bufnrs
                if bufname(j) == g:mftag_func_list_name
                    echomsg 'Function list is already opened. -> tab=' . i . ', win=' . j
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
            " no arguments => use the filetype of current buffer
            let l:ft = {&filetype:''}
        elseif (a:0==1) && (a:1 == 'help')
            echo s:echo_mftag_usage('')
            return
        elseif (a:0==1) && (a:1 == 'del')
            call mftags#delete_buffer()
            return
        else
            let l:ft = {}
            let is_del = 0
            let is_help = 0
            for i in range(1, a:0)
                let idx = stridx(a:[i], '-')
                if idx == -1
                    let tmp_ft = a:[i]
                    let tmp_kinds = ''
                else
                    let tmp_ft = a:[i][:idx-1]
                    let tmp_kinds = a:[i][idx+1:]
                endif

                if tmp_ft == 'help'
                    let is_help = 1
                    continue
                endif
                if tmp_ft == 'del'
                    let is_del = 1
                    continue
                endif

                let l:ft[tmp_ft] = tmp_kinds
            endfor

            if is_del == 1
                echo 'del is not callable with filetypes!'
                return
            endif

            if is_help == 1
                for tmp_ft in keys(l:ft)
                    echo s:echo_mftag_usage(tmp_ft)
                endfor
                return
            endif
        endif

        if tagfiles() == []
            echoerr "Tag file is not found."
            return
        endif

        call MFshow_func_list(l:ft)

        " return values
        execute "set report=" . l:old_report

    endfunction

    function! s:funclist_comp(arglead, cmdline, cursorpos) abort
        let arglead = tolower(a:arglead)
        let cmdline = tolower(a:cmdline)
        let def_en_kinds = mftags#get_def_en_kinds()
        let idx = stridx(arglead, '-')
        if match(keys(def_en_kinds), '^'.arglead.'$') != -1
            " filetypeの入力完
            return [arglead.'-']
        elseif idx != -1
            " -の後
            let ft = arglead[:idx-1]
            if match(keys(def_en_kinds), ft) == -1
                return []
            endif

            let tmp_kind_list = split(def_en_kinds[ft], '\zs')
            let kind_list = []
            for k in tmp_kind_list
                if match(arglead[idx+1:], k) == -1
                    let kind_list += [k]
                endif
            endfor
            " もう入力されているkindを除外
            let res = filter(kind_list, 'stridx(tolower(v:val), arglead[-1:])')
            " 入力されている値をlistの頭に追加
            return split(arglead.join(res, ' '.arglead))
        else
            " filetype を入力中
            let res = keys(def_en_kinds)
            let res += ['help', 'del']
            return filter(res, '!stridx(tolower(v:val), arglead)')
        endif
    endfunction

    command! -nargs=* -complete=customlist,s:funclist_comp MFfunclist :call s:MFtag_list_usage(<f-args>)

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
        execute "autocmd MFtags BufEnter ".g:mftag_func_list_name." nested"
                    \ ." call s:funclist_auto_close()"
    endif

endif
" }}}

