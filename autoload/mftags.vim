
let s:mftag_debug = 0
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.

if has('python3')
    command! -nargs=1 Python python3 <args>
    command! -nargs=1 Pyfile py3file <args>
else
    command! -nargs=1 Python python <args>
    command! -nargs=1 Pyfile pyfile <args>
endif

let s:file = expand("<sfile>")
function! s:MFdebug( level, str ) abort
    if a:level > s:mftag_debug
        return
    endif
    if a:str == ""
        let l:db_print = "###debug### " . "@ " . s:file . " " . expand("<sfile>")
    else
        let l:db_print =  "###debug### " . str
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

Pyfile <sfile>:h/mftags/src/python/mftags_src.py
let s:src_dir = expand('<sfile>:h') . "/mftags"

Python import vim

function! mftags#make_tag_syntax_file() abort

    ""make tag path list
    "Python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

    " just set tagfiles
    if tagfiles() == []
        echo "Tag file is not found."
        return
    endif
    Python search_tag(vim.eval("tagfiles()"))

    "check file type
    if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
        echo "not suppourted file type!"
        return
    endif

    "call python function
    call s:MFdebug(1, "")
    Python make_tag_syntax_files(vim.eval('s:src_dir'), vim.eval("&filetype"), vim.eval("b:mftag_save_dir"), vim.eval("g:mftag_syntax_overwrite"), vim.eval("s:mftag_enable_syntax"))
    execute "source " . b:mftag_save_dir . "." . &filetype . "_tag_syntax.vim"
    "clean tag parh list
    Python clean_tag()
endfunction

function! mftags#show_kind_list(file_type, file_path, kind_char, tag_files) abort

    ""make tag path list
    "Python search_tag(vim.eval("&tags"), vim.eval("a:file_path"))
    " just set tagfiles
    Python search_tag(vim.eval("a:tag_files"))

    " put list on current buffer
    Python show_list_on_buf(vim.eval('s:src_dir'), vim.eval('a:file_type'), vim.eval('a:kind_char'))

    "clean tag path list and buffer
    Python clean_tag()

    "return l:list_from_tag
endfunction

function! mftags#delete_buffer() abort
    Python delete_buffer()
endfunction

