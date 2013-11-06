
if !executable(g:marching_clang_command)
	finish
endif

setlocal omnifunc=marching#complete

let b:marching_clang_command_default_options = "-cc1 -fsyntax-only"

augroup plugin-marching-filetype
	autocmd! * <buffer>
	autocmd InsertCharPre <buffer> call marching#check_complete_always()
	autocmd InsertLeave   <buffer> call marching#clang_command#cancel()
augroup END

