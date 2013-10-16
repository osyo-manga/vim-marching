
if !executable(g:marching_clang_command)
	finish
endif

setlocal omnifunc=marching#complete


augroup plugin-marching
	autocmd! * <buffer>
	autocmd InsertCharPre <buffer> call marching#clang_command#update_complete_process()
	autocmd InsertLeave   <buffer> call marching#clang_command#cancel()
augroup END

