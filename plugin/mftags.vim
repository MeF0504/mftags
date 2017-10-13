
"指定したdirectoryでctagsを実行
function! Exe_ctags(dir)

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
"tag fileを作りたいdirectory名一覧を変数として作っておいて、
"call Exe_ctags(g:dir)するとhitしたdirectoryでctagsを実行
"commandかmapすると楽。
"~~sample~~
"let g:ctag_dir = ["work","top_dir"]
"command! Ctags call Exe_ctags(g:ctag_dir)
