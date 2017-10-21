
pyfile <sfile>:h:h/python/mftags_src.py

python import vim

python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

function! mftags#make_tag_syntax_file()
    python make_tag_syntax_files(vim.eval("&filetype"))
endfunction

