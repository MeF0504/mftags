
let s:mftag_debug = 0
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.

if has('python3')
    command! -nargs=1 MFLocalPython python3 <args>
    python3 import vim
    function! s:load_pyfile(pyfy)
        execute "pyfile " . a:pyfy
    endfunction
elseif has('python')
    command! -nargs=1 MFLocalPython python <args>
    python import vim
    function! s:load_pyfile(pyfy)
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

function! mftags#make_tag_syntax_file() abort

    ""make tag path list
    "MFLocalPython search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

    " just set tagfiles
    if tagfiles() == []
        echo "Tag file is not found."
        return
    endif
    MFLocalPython search_tag(vim.eval("tagfiles()"))

    "check file type
    if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
        echo "not suppourted file type!"
        return
    endif

    "call python function
    call s:MFdebug(1, "")
    MFLocalPython make_tag_syntax_files(vim.eval('s:src_dir'), vim.eval("&filetype"), vim.eval("b:mftag_save_dir"), vim.eval("g:mftag_syntax_overwrite"), vim.eval("s:mftag_enable_syntax"))
    execute "source " . b:mftag_save_dir . "." . &filetype . "_tag_syntax.vim"
    "clean tag parh list
    MFLocalPython clean_tag()
endfunction

function! mftags#show_kind_list(file_type, file_path, kind_char, tag_files) abort

    ""make tag path list
    "MFLocalPython search_tag(vim.eval("&tags"), vim.eval("a:file_path"))
    " just set tagfiles
    MFLocalPython search_tag(vim.eval("a:tag_files"))

    " put list on current buffer
    MFLocalPython show_list_on_buf(vim.eval('s:src_dir'), vim.eval('a:file_type'), vim.eval('a:kind_char'))

    "clean tag path list and buffer
    MFLocalPython clean_tag()

    "return l:list_from_tag
endfunction

function! mftags#tag_jump(ft, tag_name) abort

    MFLocalPython jump_func(vim.eval('a:ft'), vim.eval('a:tag_name'))
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

function! mftags#delete_buffer() abort
    MFLocalPython delete_buffer()
endfunction

