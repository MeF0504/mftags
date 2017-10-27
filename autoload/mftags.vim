
if !exists('g:mftag_syntax_overwrite')
    let g:mftag_syntax_overwrite = 1
endif

if !exists('g:mftag_python_enable_kinds')
    let g:mftag_python_enable_kinds = "cfmvi"
endif
if !exists('g:mftag_c_enable_kinds')
    let g:mftag_c_enable_kinds = "cdefglmnpstuvx"
endif
if !exists('g:mftag_cpp_enable_kinds')
    let g:mftag_cpp_enable_kinds = "cdefglmnpstuvx"
endif
if !exists('g:mftag_vim_enable_kinds')
    let g:mftag_vim_enable_kinds = "acfmv"
endif

let $PYTHONPATH = $PYTHONPATH . expand("<sfile>:h:h") . "/src/python"
pyfile <sfile>:h:h/src/python/mftags_src.py

python import vim

python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

function! mftags#make_tag_syntax_file()

    "check file type
    if (&filetype != 'c') && (&filetype != 'cpp') && (&filetype != 'python') && (&filetype != 'vim')
        echo "not suppourted file type!"
        return
    endif

    execute "let l:mftag_enable_kinds = g:mftag_".&filetype."_enable_kinds"
    python make_tag_syntax_files(vim.eval("&filetype"), vim.eval("g:mftag_save_dir"), vim.eval("g:mftag_syntax_overwrite"), vim.eval("l:mftag_enable_kinds"))
    execute "source " . g:mftag_save_dir . "/" . &filetype . "_tag_syntax.vim"
endfunction

