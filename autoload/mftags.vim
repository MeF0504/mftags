
let s:mftag_debug = g:mftag_debug_manage[1]
" 0 ... no debug print.
" 1 ... low level debug print (mainly print function name).
" 2 ... normal level debug print.
" 3 ... high level debug print.

let s:file = expand("<sfile>")
function! s:MFdebug( level, str )
    if a:level > s:mftag_debug
        return
    endif
    if str == ""
        let db_print = "###debug### " . "@ " . s:file . " " . expand("<sfile>")
    else
        let l:db_print =  "###debug### " . str
    endif
    echo l:db_print
endfunction


if !exists('g:mftag_syntax_overwrite')
    let g:mftag_syntax_overwrite = 1
endif

if !exists('g:mftag_syntax_python_enable_kinds')
    let g:mftag_syntax_python_enable_kinds = "cfmvi"
endif
if !exists('g:mftag_syntax_c_enable_kinds')
    let g:mftag_syntax_c_enable_kinds = "cdefglmnpstuvx"
endif
if !exists('g:mftag_syntax_cpp_enable_kinds')
    let g:mftag_syntax_cpp_enable_kinds = "cdefglmnpstuvx"
endif
if !exists('g:mftag_syntax_vim_enable_kinds')
    let g:mftag_syntax_vim_enable_kinds = "acfmv"
endif

pyfile <sfile>:h/mftags/src/python/mftags_src.py
let s:src_dir = expand('<sfile>:h') . "/mftags"

python import vim

python set_debug_level(vim.eval("g:mftag_debug_manage[2]"))

function! mftags#make_tag_syntax_file()

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

    " just set tagfiles
    if tagfiles() == []
        echo "Tag file is not found."
        return
    endif
    python search_tag(vim.eval("tagfiles()"))

    "check file type
    if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
        echo "not suppourted file type!"
        return
    endif

    execute "let l:mftag_enable_kinds = g:mftag_syntax_".&filetype."_enable_kinds"
    "call python function
    call s:MFdebug(1, "")
    python make_tag_syntax_files(vim.eval('s:src_dir'), vim.eval("&filetype"), vim.eval("b:mftag_save_dir"), vim.eval("g:mftag_syntax_overwrite"), vim.eval("l:mftag_enable_kinds"))
    execute "source " . b:mftag_save_dir . "/" . &filetype . "_tag_syntax.vim"
    "clean tag parh list
    python clean_tag()
endfunction

function! mftags#show_kind_list(file_type, file_path, kind_char)

    ""make tag path list
    "python search_tag(vim.eval("&tags"), vim.eval("a:file_path"))
    " just set tagfiles
    python search_tag(vim.eval("tagfiles()"))

    " put list on current buffer
    python show_list_on_buf(vim.eval('s:src_dir'), vim.eval('a:file_type'), vim.eval('a:kind_char'))

    "clean tag path list and buffer
    python clean_tag()

    "return l:list_from_tag
endfunction

function! mftags#delete_buffer()
    python delete_buffer()
endfunction

