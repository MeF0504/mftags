
if !exists('g:mftag_syntax_overwrite')
    let g:mftag_syntax_overwrite = 1
endif

let $PYTHONPATH = $PYTHONPATH . expand("<sfile>:h:h") . "/src/python"
pyfile <sfile>:h:h/src/python/mftags_src.py

python import vim

python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

function! mftags#make_tag_syntax_file()
    python make_tag_syntax_files(vim.eval("&filetype"), vim.eval("g:mftag_save_dir"), vim.eval("g:mftag_syntax_overwrite"))
    execute "source " . g:mftag_save_dir . "/" . &filetype . "_tag_syntax.vim"
endfunction

