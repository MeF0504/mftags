
let s:mftag_debug = 0
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.

if !has('pythonx')
    echo 'this function requires python or python3'
    exit
endif

let s:file = expand("<sfile>")
function! s:MFdebug( level, str ) abort
    if a:level > s:mftag_debug
        return
    endif
    if a:str == ""
        let l:db_print = "###debug### " . "@ " . s:file . " " . expand("<sfile>")
    else
        let l:db_print =  "###debug### " . a:str
    endif
    echo l:db_print
endfunction

" {{{ basic settings.
if exists('g:mftag_python_setting')
    if has_key(g:mftag_python_setting, 'syntax')
        let s:mftag_enable_syntax = g:mftag_python_setting['syntax']
    elseif has_key(g:mftag_python_setting, 'tag')
        let s:mftag_enable_syntax = g:mftag_python_setting['tag']
    else
        let s:mftag_enable_syntax = "cfmvi"
    endif
endif
if exists('g:mftag_c_setting')
    if has_key(g:mftag_c_setting, 'syntax')
        let s:mftag_enable_syntax = g:mftag_c_setting['syntax']
    elseif has_key(g:mftag_c_setting, 'tag')
        let s:mftag_enable_syntax = g:mftag_c_setting['tag']
    else
        let s:mftag_enable_syntax = "cdefglmnpstuvx"
    endif
endif
if exists('g:mftag_cpp_setting')
    if has_key(g:mftag_cpp_setting, 'syntax')
        let s:mftag_enable_syntax = g:mftag_cpp_setting['syntax']
    elseif has_key(g:mftag_cpp_setting, 'tag')
        let s:mftag_enable_syntax = g:mftag_cpp_setting['tag']
    else
        let s:mftag_enable_syntax = "cdefglmnpstuvx"
    endif
endif
if exists('g:mftag_vim_setting')
    if has_key(g:mftag_vim_setting, 'syntax')
        let s:mftag_enable_syntax = g:mftag_vim_setting['syntax']
    elseif has_key(g:mftag_vim_setting, 'tag')
        let s:mftag_enable_syntax = g:mftag_vim_setting['tag']
    else
        let s:mftag_enable_syntax = "acfmv"
    endif
endif

if !exists('s:mftag_enable_syntax')
    if &filetype == 'python'
        let s:mftag_enable_syntax = "cfmvi"
    elseif (&filetype == 'c') || (&filetype == 'cpp')
        let s:mftag_enable_syntax = "cdefglmnpstuvx"
    elseif &filetype == 'vim'
        let s:mftag_enable_syntax = "acfmv"
    endif
endif
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
    if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
        echo "not suppourted file type!"
        return
    endif

    "call python function
    call s:MFdebug(1, "")
    pythonx make_tag_syntax_files(
                \ vim.eval('&filetype'), vim.eval('b:mftag_save_dir'),
                \ vim.eval('g:mftag_syntax_overwrite'), vim.eval('s:mftag_enable_syntax'))
    execute "source " . b:mftag_save_dir . "." . &filetype . "_tag_syntax.vim"
    "clean tag parh list
    pythonx clean_tag()
endfunction

function! mftags#show_kind_list(file_types, file_path, kinds, tag_files) abort

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("a:file_path"))
    " just set tagfiles
    pythonx search_tag(vim.eval('a:tag_files'))

    if exists('g:mftag_popup_on') && g:mftag_popup_on != 0
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
        if exists('g:mftag_popup_on') && g:mftag_popup_on != 0
            return
        endif
        let file_num = len(g:tmp_dic)
        if file_num == 0
            echo "can't find matching line."
            return
        endif

        echo file_num
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

