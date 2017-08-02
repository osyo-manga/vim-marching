#marching.vim

Clang を使用して非同期で C++ のコード補完を行うためのプラグインです。

Document in English is [here](https://github.com/osyo-manga/vim-marching/blob/master/doc/marching.txt).

##Requirement

* __Executable__
 * __[Clang](http://clang.llvm.org/)__
* __Vim plugin__
 * __[vimproc.vim](https://github.com/Shougo/vimproc.vim)__


##Screencapture
![test](https://f.cloud.github.com/assets/214488/1419479/bf4c31d6-3fcc-11e3-97fb-928f8006691e.gif)

![marching1](https://f.cloud.github.com/assets/214488/1320244/ff09818e-334c-11e3-8569-075f31b50984.gif)


![marching2](https://f.cloud.github.com/assets/214488/1320247/0d6e8e5e-334d-11e3-9a62-3b586a247144.gif)


##Setting
```vim
" clang コマンドの設定
let g:marching_clang_command = "C:/clang.exe"

" オプションを追加する
" filetype=cpp に対して設定する場合
let g:marching#clang_command#options = {
\	"cpp" : "-std=gnu++1y"
\}

" インクルードディレクトリのパスを設定
let g:marching_include_paths = [
\	"C:/MinGW/lib/gcc/mingw32/4.6.2/include/c++"
\	"C:/cpp/boost"
\]

" neocomplete.vim と併用して使用する場合
let g:marching_enable_neocomplete = 1

if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

let g:neocomplete#force_omni_input_patterns.cpp =
	\ '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*'

" 処理のタイミングを制御する
" 短いほうがより早く補完ウィンドウが表示される
" ただし、marching.vim 以外の処理にも影響するので注意する
set updatetime=200

" オムニ補完時に補完ワードを挿入したくない場合
imap <buffer> <C-x><C-o> <Plug>(marching_start_omni_complete)

" キャッシュを削除してからオムに補完を行う
imap <buffer> <C-x><C-x><C-o> <Plug>(marching_force_start_omni_complete)


" _数値 から始まる候補を無視する
let g:marching#default_config = {
\	"ignore_pat" : '^_\D'
\}

" 非同期ではなくて、同期処理でコード補完を行う場合
" この設定の場合は vimproc.vim に依存しない
" let g:marching_backend = "sync_clang_command"
```


##Future

* C++ 以外の対応
 * Objective-C
* スニペットの対応
* neocomplete.vim との連携


##License

[NYSL](http://www.kmonos.net/nysl/)

[NYSL English](http://www.kmonos.net/nysl/index.en.html)


