scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim



function! marching#sync_clang_command#complete(context)
	echo "marching completion start"

	let tempfile = marching#clang_command#make_tempfile(fnamemodify(a:context.bufnr, ":p:h") . "/sync_marching_complete_temp.cpp", a:context.bufnr)
	if !filereadable(tempfile)
		return
	endif
	try
		let command = marching#clang_command#clang_complete_command(
\			get(b:, "marching_clang_command", g:marching_clang_command),
\			tempfile,
\			a:context.pos[0],
\			a:context.pos[1],
\			marching#clang_command#include_opt() . " " . get(b:, "marching_clang_command_option", g:marching_clang_command_option)
\		)
		call marching#print_log("sync_clang_command command", command)

		let has_vimproc = 0
		silent! let has_vimproc = vimproc#version()
		if has_vimproc
			let result = vimproc#system(command)
		else
			let result = system(command)
		endif

		echo "marching completion finish"
		return marching#clang_command#parse_complete_result(result)
	finally
		call delete(tempfile)
	endtry
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
