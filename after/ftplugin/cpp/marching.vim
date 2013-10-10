
if !executable(g:marching_command)
	finish
endif

setlocal omnifunc=marching#complete


augroup plugin-marching
	autocmd! * <buffer>
	autocmd InsertLeave <buffer> call marching#complete#clear_complete_cache()
	autocmd InsertCharPre <buffer> call marching#complete#update_complete_process()
augroup END

