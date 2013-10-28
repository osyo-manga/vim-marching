
if !executable(g:marching_clang_command)
	finish
endif

setlocal omnifunc=marching#complete


augroup plugin-marching-filetype
	autocmd! * <buffer>
	autocmd InsertCharPre <buffer> call marching#check_complete_always()
	autocmd InsertLeave   <buffer> call marching#clang_command#cancel()
augroup END

