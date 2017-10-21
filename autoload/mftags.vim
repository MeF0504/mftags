
pyfile <sfile>:h:h/python/mftags_src.py

python import vim

function! mftags#tag_search()
    echo &tags
    python search_tag(vim.eval("&tags"), vim.eval("expand('%:p')"))

    python make_tag_syntax_files(vim.eval("&filetype"))
endfunction

