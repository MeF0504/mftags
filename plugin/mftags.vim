
if exists('g:mftag_loaded')
    finish
endif
let g:mftag_loaded = 1

"########## global settings
function! MFsearch_dir(dir)
    let l:curdir = expand('%:p:h') . "/"

    for d in a:dir
        let d = '\<' . d . '\>'
        let l:n = matchend(l:curdir,d)
        if l:n != -1
            "echo l:curdir[:l:n]
            return l:curdir[:l:n]
        endif
    endfor
    echo "no match directory"
    return ''
endfunction

if exists('g:mftag_dir') && !exists('g:mftag_save_dir')
    let g:mftag_save_dir = MFsearch_dir(g:mftag_dir)
elseif !exists('g:mftag_save_dir')
    let g:mftag_save_dir = getcwd()
endif

if has('win32')
    let s:sep = '\'
else
    let s:sep = '/'
endif
if g:mftag_save_dir[strlen(g:mftag_save_dir)-1] != s:sep
    let g:mftag_save_dir = g:mftag_save_dir . s:sep
endif

"########## tags syntax setting
if !exists('g:mftag_no_need_MFsyntax')
    function! s:check_and_read_file(ft)
        let l:filename = g:mftag_save_dir . a:ft . "_tag_syntax.vim"
        if filereadable(l:filename)
            execute "source " . l:filename
        endif
    endfunction
    
    autocmd FileType python call s:check_and_read_file(&filetype)
    autocmd FileType c call s:check_and_read_file(&filetype)
    autocmd FileType cpp call s:check_and_read_file(&filetype)
    autocmd FileType vim call s:check_and_read_file(&filetype)

    command! MFsyntax :call mftags#make_tag_syntax_file()

endif
"########## execute ctag setting
if !exists('g:mftag_no_need_MFctag')

    if !exists('g:mftag_dir')
        let g:mftag_dir = ['']
    endif
    if !exists('g:mftag_exe_option')
        let g:mftag_exe_option = '-R'
    endif
    
    "execute ctags command at specified directory
    "specify directory name by setting valiabe 'g:mftag_dir'
    "ex) g:mftag_dir = ['work','top','hoge']
    "   I'm opening file @ /home/to/work/dir/src
    "   => make tags file @ /home/to/work
    "   I'm opening file @ /from/top/dir/to/hoge/project/src
    "   => make tags file @ /from/top/
    "   I'm opening file @ /home/to/work/dir/work/dir/src
    "   => make tags file @ /from/to/work/dir/work
    function! MFexe_ctags(dir)
    
        let l:pwd = getcwd()
        let l:exe_dir = MFsearch_dir(a:dir)
        echo l:exe_dir
        if l:exe_dir == ''
            return
        endif
        sleep 2
        execute "cd " . l:exe_dir
        execute "! ctags " . g:mftag_exe_option
    
        execute "cd " . l:pwd
    endfunction
    
    command! MFctag :call MFexe_ctags(g:mftag_dir)

endif

