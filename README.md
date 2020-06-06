
# MF tags
vimでctagsを使用する際に，自分のやりたかった関数群。
g:loaded_mftagsが存在すると読み込みません。

実証環境:
・vim : VIM - Vi IMproved 8.0 (need +python or +python3)
・ctags : Exuberant Ctags 5.8

対応言語：python, c, cpp, vim


できるコマンドは3つ:
## MFctag
ctagsをvimから実行します。

作成する場所は， g:mftag_ankで指定する名前のファイルがある場合はそのファイルと同じ場所に，ない場合はg:mftag_dir_auto_set，g:mftag_dirに従って作成されます。

設定用の変数は
* g:mftag_ank : この変数が指定するファイルと同じ場所にtagを作成します。初期値は".mfank"

  ex) /path/to/ank/.mfank -> make tags @ /psth/to/ank/
* g:mftag_no_need_MFctag : この変数があるとMFctag関連の設定を読み込みません。
* g:mftag_dir_auto_set : この変数が1だと，カレントディレクトリの上に.git, .svnを見つけた場合，その位置でctagsを実行してくれます。
* g:mftag_dir : ctagsの実行位置を決定する変数。型はlist。g:mftag_dir_auto_setが1の場合，この変数は無視されます。

  ex) g:mftag_dir = ['work','top','hoge']

     I'm opening file @ /home/to/work/dir/src

     => make tags file @ /home/to/work

     I'm opening file @ /from/top/dir/to/hoge/project/src

     => make tags file @ /from/top/

     I'm opening file @ /home/to/work/dir/work/dir/src

     => make tags file @ /from/to/work/dir/work

     こんな感じで，配列の最初から順に一致するディレクトリ名を探してヒットしたら実行します。
* g:mftag_exe_option : ctagsのオプションです。型はstring 。
  デフォルトはg:mftag_exe_option = '-R'
* g:mftag_{filttype}\_setting['tag'] : tagを作成する際のkindを指定します。指定しなければctagsコマンドの設定に従います。

## MFsyntax
tagsファイルを探し出して情報を読み取り，見つけた文字列に基づいたsyntaxを追加します。

設定用の変数は
* g:mftag_no_need_MFsyntax : この変数があるとMFsyntax関連の設定を読み込みません。
* g:mftag_save_dir : 作成したsyntaxファイルの保存場所を指定します。型はstring。
  自分でg:mftag_save_dirを指定していない場合，{g:mftag_ank} ファイル，g:mftag_dir_auto_set，g:mftag_dirで指定される場所の順で指定されます。
  何も指定していない場合はカレントディレクトリです。
  実際に使われる値はb:mftag_save_dirを参照。
* g:mftag_syntax_overwrite : 1ならばsyntax fileを作る際に新しく作り直します。0ならばsyntax fileがある場合には追記します。デフォルトは1。
* g:mftag_{filetype}\_setting['syntax']
  : それぞれ言語ごとにsyntaxを作るctagsのkindを示しています。例えば，let g:mftag_c_setting['syntax'] = "dst"とすれば，c言語ではmacro definitionsとstructure namesとtypedefsのみに色がつきます。設定しなければg:mftag_{filetype}\_setting['tag']の設定に従い，そちらも無ければ全指定になります。

  参考 : test/ctags_list_kinds.txt

## MFfunclist
tagファイルを探し出して情報を読み取り，関数などの一覧を表示します。

設定用の変数は
* g:mftag_no_need_MFfunclist : この変数があるとMFfunclist関連の設定を読み込みません。
* g:mftag_func_list_name : function listのwindowの名前を設定しています。デフォルトは"MF_func_list"。
* g:mftag_func_list_width : function listのwindowの幅を設定します。デフォルトは40。
* g:mftag_auto_close : この変数が1だと，function list以外のwindowが閉じた場合に自動でfunction listのwindowを閉じます。デフォルトはoff。
* g:mftag_popup_on : この変数が0以外だと，function listをpopupで表示します。選択された関数は新しいtabで開かれます。defaultは0.
* g:mftag_{filetype}\_setting['func']
  それぞれの言語で，MFfunclistを実行した際に表示されるkindを設定できます。設定がない場合はg:mftag_{filetype}\_setting['tag']の設定が，そちらもない場合はすべて表示されます。

機能としては，:MFfunclist <filetype>で見つけたすべてのtagsファイルの関数一覧を表示します。filetypeはカンマ(,)区切りで複数設定可です。 ex) :MFfunclist python,c

<filetype>に何もない場合は，現在開いているfiletypeのものが表示されます。

:MFfunclist <filetype> help で利用可能なkindを見ることが出来ます。

key mapは
* \+       : すべてのfoldを開きます。
* \-       : カーソルのある行のfoldを閉じます。
* =       : すべてのfoldを閉じます。
* \<enetr> : foldがあれば開き，それ以外ではカーソル下の文字の定義元を隣のウィンドウで開きます。
* \<c-t> : カーソル下の文字の定義元を新しいタブで開きます。
* q       : ウィンドウを閉じます。

