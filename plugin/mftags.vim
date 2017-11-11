
if exists('g:mftag_loaded')
    finish
endif
let g:mftag_loaded = 1
let s:mftag_start_up = 1
let s:mftag_debug = 0

augroup MFtags
    autocmd!
augroup END

"########## global settings

let s:file = expand("<sfile>")
function! s:MFdebug()
    echo "###debug###"
    "echo "@ " . s:file . " " . expand("<sfile>") . " line " . expand("<slnum>")
    echo "@ " . s:file . " " . expand("<sfile>")
endfunction


function! MFsearch_dir(dir)
    let l:curdir = expand('%:p:h') . "/"

    for d in a:dir
        let d = '\<' . d . '\>'
        let l:n = matchend(l:curdir,d)
        if l:n != -1
            if s:mftag_debug == 1
                call s:MFdebug()
                echo l:curdir[:l:n]
            endif
            return l:curdir[:l:n]
        endif
    endfor
    if !exists("s:mftag_start_up")
        echo "no match directory"
    endif
    return ''
endfunction

function! s:set_mftag_save_dir()
    if exists('g:mftag_dir') && !exists('g:mftag_save_dir')
        let b:mftag_save_dir = MFsearch_dir(g:mftag_dir)
        if s:mftag_debug == 1
            call s:MFdebug()
            echo "s:set_mftag_save_dir 1"
        endif
    elseif !exists('g:mftag_save_dir')
        let b:mftag_save_dir = getcwd()
        if s:mftag_debug == 1
            call s:MFdebug()
            echo "s:set_mftag_save_dir 2"
        endif
    else
        let b:mftag_save_dir = g:mftag_save_dir
        if s:mftag_debug == 1
            call s:MFdebug()
            echo "s:set_mftag_save_dir 3"
        endif
    endif

    if has('win32')
        let s:sep = '\'
    else
        let s:sep = '/'
    endif
    if b:mftag_save_dir[strlen(b:mftag_save_dir)-1] != s:sep
        let b:mftag_save_dir = b:mftag_save_dir . s:sep
    endif
endfunction

call s:set_mftag_save_dir()

unlet s:mftag_start_up

"########## tags syntax setting
if !exists('g:mftag_no_need_MFsyntax')
    function! s:check_and_read_file(ft)
        call s:set_mftag_save_dir()
        let l:filename = b:mftag_save_dir . a:ft . "_tag_syntax.vim"
        if filereadable(l:filename)
            execute "source " . l:filename
        endif
    endfunction
    
    autocmd MFtags FileType python call s:check_and_read_file(&filetype)
    autocmd MFtags FileType c call s:check_and_read_file(&filetype)
    autocmd MFtags FileType cpp call s:check_and_read_file(&filetype)
    autocmd MFtags FileType vim call s:check_and_read_file(&filetype)

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

