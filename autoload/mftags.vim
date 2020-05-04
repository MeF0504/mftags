
let s:mftag_debug = 0
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.

if has('python3')
    python3 import vim

    function! s:call_python(...) abort
        if a:0 == 0
            call MFdebug(1, 'please input function!')
            return 0
        endif
        let py_exe_cmd = ""
        for i in range(a:0-1)
            let py_exe_cmd .= "vim.eval('a:" . (i+2) . "'), "
        endfor
        execute "python3 " . a:1 . '(' .  py_exe_cmd . ')'
    endfunction

    function! s:load_pyfile(pyfy) abort
        execute "py3file " . a:pyfy
    endfunction

elseif has('python')
    python import vim

    function! s:call_python(...) abort
        if a:0 == 0
            call MFdebug(1, 'please input function!')
            return 0
        endif
        let py_exe_cmd = ""
        for i in range(a:0-1)
            let py_exe_cmd .= "vim.eval('a:" . (i+2) . "'), "
        endfor
        execute "python " . a:1 . '(' .  py_exe_cmd . ')'
    endfunction

    function! s:load_pyfile(pyfy) abort
        execute "pyfile " . a:pyfy
    endfunction

else
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


if !exists('g:mftag_syntax_overwrite')
    let g:mftag_syntax_overwrite = 1
endif

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

call s:load_pyfile(expand("<sfile>:h") . "/mftags/src/python/mftags_src.py")
let s:src_dir = expand('<sfile>:h') . "/mftags"

call s:call_python('set_src_path', s:src_dir)

function! mftags#make_tag_syntax_file() abort

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

    " just set tagfiles
    if tagfiles() == []
        echo "Tag file is not found."
        return
    endif
    call s:call_python('search_tag', tagfiles())

    "check file type
    if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
        echo "not suppourted file type!"
        return
    endif

    "call python function
    call s:MFdebug(1, "")
    call s:call_python('make_tag_syntax_files', &filetype, b:mftag_save_dir, g:mftag_syntax_overwrite, s:mftag_enable_syntax)
    execute "source " . b:mftag_save_dir . "." . &filetype . "_tag_syntax.vim"
    "clean tag parh list
    call s:call_python('clean_tag')
endfunction

function! mftags#show_kind_list(file_type, file_path, kind_char, tag_files) abort

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("a:file_path"))
    " just set tagfiles
    call s:call_python('search_tag', a:tag_files)

    " put list on current buffer
    call s:call_python('show_list_on_buf', a:file_type, a:kind_char)

    "clean tag path list and buffer
    call s:call_python('clean_tag')

    "return l:list_from_tag
endfunction

function! mftags#tag_jump(ft, kind, tag_name) abort

    call s:call_python('jump_func', a:ft, a:kind, a:tag_name)
    " python in vim doesn't support input.
    if exists('g:tmp_dic')
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
        call s:call_python('show_def', a:filetype, a:kind, a:tag_name)
    endif
endfunction

function! mftags#delete_buffer() abort
    call s:call_python('delete_buffer')
endfunction

