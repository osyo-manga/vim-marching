scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! marching#debug#run_command()
	let context = marching#current_context()
	return marching#clang_command#clang_complete_command(
\		get(b:, "marching_clang_command", g:marching_clang_command),
\		bufname("%"),
\		context.pos[0],
\		context.pos[1] + 1,
\		marching#clang_command#option(),
\	)
endfunction

function! marching#debug#check()
	call marching#clear_log()
	call marching#clear_cache_all()
	call marching#clang_command#cancel()
	let context = marching#current_context()
	let old_debug = g:marching_debug
	let g:marching_debug = 1
	try
		let result = marching#sync_clang_command#complete(marching#current_context())
	finally
		let g:marching_debug = old_debug
	endtry
	call marching#clear_cache(context)
	return marching#log() . "\n" . join(result, "\n")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
