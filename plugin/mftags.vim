
"########## tags syntax setting
if has('win32')
    let g:mftag_vimdir = expand('~/vimfiles/')
else
    let g:mftag_vimdir = expand('~/.vim/')
endif

highlight default MFdef ctermfg=213

autocmd FileType python execute "source " . g:mftag_vimdir . "src/" . &filetype . "_tag_syntax.vim"

"########## execute ctag setting
"execute ctags command at specified directory
"specify directory name by setting valiabe 'g:ctag_dir'
"ex) g:ctag_dir = ['work','top','hoge']
"   I'm opening file @ /home/to/work/dir/src
"   => make tags file @ /home/to/work
"   I'm opening file @ /from/top/dir/to/hoge/project/src
"   => make tags file @ /from/top/
"   I'm opening file @ /home/to/work/dir/work/dir/src
"   => make tags file @ /from/to/work/dir/work
function! MFexe_ctags(dir)

    let l:end = 0
    let l:curdir = expand('%:p:h') . "/"
    let l:pwd = getcwd()
    "echo l:curdir

    for d in a:dir
        let d = '\<' . d . '\>'
        "echo d

        let l:n = matchend(l:curdir,d)
        if l:n != -1
            let l:end=1
            echo l:curdir[:l:n]
            sleep 1
            execute "cd " . l:curdir[:l:n]
            ! ctags -R
            break
        endif
    endfor
    if l:end==0
        echo "no match directory"
    endif
    execute "cd " . l:pwd
endfunction


