
if !empty(g:marching_clang_command) && !executable(g:marching_clang_command)
	finish
endif


setlocal omnifunc=marching#complete

" NOTE:http://yuttie.hatenablog.jp/entry/2014/02/11/151610
let b:marching_clang_command_default_options = "-fsyntax-only -std=c++11"

augroup plugin-marching-filetype
	autocmd! * <buffer>
	autocmd InsertCharPre <buffer> call marching#check_complete_always()
	autocmd InsertLeave   <buffer> call marching#clang_command#cancel()
augroup END

