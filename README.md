#marching.vim

Clang を使用して非同期で C++ のコード補完を行うためのプラグインです。

Document in English is [here](https://github.com/osyo-manga/vim-marching/blob/master/doc/marching.txt).

##Requirement

* __Executable__
 * __[Clang](http://clang.llvm.org/)__
* __Vim plugin__
 * __[vimproc.vim](https://github.com/Shougo/vimproc.vim)__
 * __[reunions.vim](https://github.com/osyo-manga/vim-reunions)__


##Screencapture

![marching1](https://f.cloud.github.com/assets/214488/1320244/ff09818e-334c-11e3-8569-075f31b50984.gif)


![marching2](https://f.cloud.github.com/assets/214488/1320247/0d6e8e5e-334d-11e3-9a62-3b586a247144.gif)


##Setting
```vim
" clang コマンドの設定
let g:marching_clang_command = "C:/clang.exe"

" オプションを追加する場合
let g:marching_clang_command_option="-std=c++1y"

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
set updatetime=200

" オムニ補完時に補完ワードを挿入したくない場合
imap <buffer> <C-x><C-o> <Plug>(marching_start_omni_complete)

" キャッシュを削除してからオムに補完を行う
imap <buffer> <C-x><C-x><C-o> <Plug>(marching_force_start_omni_complete)


" 非同期ではなくて、同期処理でコード補完を行う場合
" let g:marching_backend = "sync_clang_command"
```


##Future

* C++ 以外の対応
 * C言語
 * Objective-C
* キャッシングの性能を上げる
* コード補完ウィンドウで表示される情報の追加
 * 関数の引数など


