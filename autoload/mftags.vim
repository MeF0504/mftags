
let s:mftag_debug = 0
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.

if !has('pythonx')
    echohl Error
    echo 'this function requires python or python3'
    echohl None
    finish
endif

if s:mftag_debug > 0
    let s:file = expand("<sfile>")
    source <sfile>:h/mftags/src/vim/debug.vim
endif

function! s:MFdebug( level, str ) abort
    if a:level <= s:mftag_debug
        call MFtagDebug(a:str, 'auto-'.a:level, s:file)
    endif
endfunction

" {{{ basic settings.
" default enable kinds
let s:def_en_kinds = {
            \ 'python': 'cfmvi',
            \ 'c': 'cdefglmnpstuvx',
            \ 'cpp': 'cdefglmnpstuvx',
            \ 'vim': 'acfmv',
            \ 'sh': 'f'
            \ }

function! s:set_syntax(filetype)
    if has_key(g:mftag_lang_setting, a:filetype)
        if has_key(g:mftag_lang_setting[a:filetype], 'syntax')
            let syntax_setting = g:mftag_lang_setting[a:filetype]['syntax']
        elseif has_key(g:mftag_lang_setting[a:filetype], 'tag')
            let syntax_setting = g:mftag_lang_setting[a:filetype]['tag']
        else
            if has_key(s:def_en_kinds, a:filetype)
                let syntax_setting = s:def_en_kinds[a:filetype]
            else
                let syntax_setting = ''
            endif
        endif
    else
        if has_key(s:def_en_kinds, a:filetype)
            let syntax_setting = s:def_en_kinds[a:filetype]
        else
            let syntax_setting = ''
        endif
    endif
    return syntax_setting
endfunction

function! mftags#get_def_en_kinds() abort
    return s:def_en_kinds
endfunction

" }}}

pythonx import vim
pyxfile <sfile>:h/mftags/src/python/mftags_src.py
let s:src_dir = expand('<sfile>:h') . "/mftags"

pythonx set_src_path(vim.eval('s:src_dir'))

function! mftags#make_tag_syntax_file() abort

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

    " just set tagfiles
    if tagfiles() == []
        echo "Tag file is not found."
        return
    endif
    pythonx search_tag(vim.eval('tagfiles()'))

    "check file type
    if (&filetype != 'c') && (&filetype != 'cpp') &&
        \ (&filetype != 'python') && (&filetype != 'vim') &&
        \ (&filetype != 'sh')
        echo "not suppourted file type!"
        return
    endif

    "call python function
    call s:MFdebug(1, "")
    let syntax_setting = s:set_syntax(&filetype)
    call s:MFdebug(1, 'set syntax; filetype:'.&filetype.' syntax::'.syntax_setting)
    pythonx make_tag_syntax_files(
                \ vim.eval('&filetype'), vim.eval('b:mftag_save_dir'),
                \ vim.eval('g:mftag_syntax_overwrite'), vim.eval('syntax_setting'))
    execute "source " . b:mftag_save_dir . "." . &filetype . "_tag_syntax.vim"
    "clean tag parh list
    pythonx clean_tag()
endfunction

function! mftags#show_kind_list(file_types, file_path, kinds, tag_files) abort

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("a:file_path"))
    " just set tagfiles
    pythonx search_tag(vim.eval('a:tag_files'))

    if exists('g:mftag_popup_on') && g:mftag_popup_on != 0 && exists('*popup_menu')
        " get list of function list
        pythonx show_list_on_pop(vim.eval('a:file_types'), vim.eval('a:kinds'))
    else
        " put list on current buffer
        pythonx show_list_on_buf(vim.eval('a:file_types'), vim.eval('a:kinds'))
    endif

    "clean tag path list and buffer
    pythonx clean_tag()

    "return l:list_from_tag
endfunction

function! mftags#tag_jump(ft, kind, tag_name) abort

    pythonx jump_func(vim.eval('a:ft'), vim.eval('a:kind'), vim.eval('a:tag_name'))
    " python in vim doesn't support input.
    if exists('g:tmp_dic')
        if exists('g:mftag_popup_on') && g:mftag_popup_on != 0 && exists('*popup_menu')
            return
        endif
        let file_num = len(g:tmp_dic)
        if file_num == 0
            echo "can't find matching line."
            return
        endif

        for i in range(file_num)
            echo '  ' . i . ' ' . g:tmp_dic[i][0] . ' : ' . g:tmp_dic[i][1] . ' lines'
        endfor

        let l:tmp_index = input('Type number and <Enter> (empty cancels) ')
        if (l:tmp_index !~ "[0-9]") || (l:tmp_index >= len(g:tmp_dic))
            call s:MFdebug(1, "incorrect input")
            unlet g:tmp_dic
            return
        endif
        let l:ind = str2nr(l:tmp_index)
        call s:MFdebug(2, "open " . g:tmp_dic[l:ind][0] . "::" . g:tmp_dic[l:ind][1])
        execute "silent e +" . g:tmp_dic[l:ind][1] . " " . g:tmp_dic[l:ind][0]
        unlet g:tmp_dic
    endif
endfunction

function! mftags#show_def(filetype, kind, tag_name)
    if len(a:tag_name) < 2
        return
    elseif a:tag_name[1] != "\t"
        echo substitute(a:tag_name, '\t', '', 'g')
    else
        pythonx show_def(vim.eval('a:filetype'), vim.eval('a:kind'), vim.eval('a:tag_name'))
    endif
endfunction

function! mftags#delete_buffer() abort
    pythonx delete_buffer()
endfunction

