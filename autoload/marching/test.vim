scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:root = expand("<sfile>:h")
echo s:root


let s:test = {}
function! s:test.clang_command(...)
	return {
\		"name" : "clang_command",
\		"ok" : executable(g:marching_clang_command),
\		"message" : printf("check executable `%s` command.", g:marching_clang_command),
\		"success_msg" : "",
\		"failure_msg" : printf("Not found `%s` command. Please install `clang` or setting `g:marching_clang_command` option to clang path.", g:marching_clang_command),
\		"log" : system(g:marching_clang_command . " -v")
\	}
endfunction


function! s:test.clang_completion()
	let cmd = marching#clang_command#clang_complete_command(
\		get(b:, "marching_clang_command", g:marching_clang_command),
\		s:root . "/test/plane.cpp",
\		8,
\		7,
\		""
\	)
	let result = system(cmd)
	return {
\		"name" : "clang_completion",
\		"ok" : v:shell_error == 0 && result =~ 'COMPLETION: value : \[#int#\]value',
\		"message" : printf("execute command `%s`", cmd),
\		"success_msg" : "",
\		"failure_msg" : "",
\		"log" : "command output:\n" . result,
\	}
endfunction


function! s:test.clang_completion_with_standard_lib()
	let cmd = marching#clang_command#clang_complete_command(
\		get(b:, "marching_clang_command", g:marching_clang_command),
\		s:root . "/test/with_standard_lib.cpp",
\		8,
\		17,
\		""
\	)
" \		marching#clang_command#option(),
	let result = system(cmd)
	return {
\		"name" : "clang_completion_with_standard_lib",
\		"ok" : v:shell_error == 0 && result =~ 'COMPLETION: base : ',
\		"message" : printf("execute command `%s`", cmd),
\		"success_msg" : "",
\		"failure_msg" : "",
\		"log" : "command output:\n" . result,
\	}
endfunction


function! s:test.marching_sync_completion()
	let context = {
\		"complete_word" : "    x.",
\		"pos" : [8, 7],
\		"bufnr" : s:root . "/test/plane.cpp",
\		"keyword" : "x.",
\		"complete_base" : "",
\		"config" : marching#get_config()
\	}
	call marching#clear_log()
	call marching#clear_cache_all()
	call marching#clang_command#cancel()
	let old_debug = g:marching_debug
	let g:marching_debug = 1

	try
		silent! let result = marching#sync_clang_command#complete(context)
	finally
		let g:marching_debug = old_debug
	endtry
	let filtered = filter(deepcopy(result), { -> !empty(v:val["word"]) })
	return {
\		"name" : "marching_sync_completion",
\		"ok" : !empty(filtered),
\		"message" : "run marching#sync_clang_command#complete()",
\		"success_msg" : "",
\		"failure_msg" : "",
\		"log" : marching#log() . "\n" . "completion result:\n". join(result, "\n")
\	}
endfunction


function! s:test.marching_sync_completion_with_standard_lib()
	let context = {
\		"complete_word" : "    str.begin().",
\		"pos" : [8, 17],
\		"bufnr" : s:root . "/test/with_standard_lib.cpp",
\		"keyword" : "str.begin().",
\		"complete_base" : "",
\		"config" : marching#get_config()
\	}
	call marching#clear_log()
	call marching#clear_cache_all()
	call marching#clang_command#cancel()
	let old_debug = g:marching_debug
	let g:marching_debug = 1

	try
		silent! let result = marching#sync_clang_command#complete(context)
	finally
		let g:marching_debug = old_debug
	endtry
	let filtered = filter(deepcopy(result), { -> !empty(v:val["word"]) })
	return {
\		"name" : "marching_sync_completion_with_standard_lib",
\		"ok" : !empty(filtered),
\		"message" : "run marching#sync_clang_command#complete()",
\		"success_msg" : "",
\		"failure_msg" : "",
\		"log" : marching#log() . "\n" . "completion result:\n". join(result, "\n")
\	}
endfunction


function! marching#test#get(name)
	return s:test[a:name]()
endfunction


function! s:hlechon(hl, msg)
	try
		execute "echohl" a:hl
		echon a:msg
	finally
		echohl NONE
	endtry
endfunction


function! s:print(result, ...)
	echo ""
	if a:result.ok
		call s:hlechon("MoreMsg", "[Success] ")
		echon printf("%s: %s", a:result.name, a:result.message)
		echo a:result.success_msg
		if get(a:, 1)
			echo a:result.log
		endif
	else
		call s:hlechon("WarningMsg", "[Failure] ")
		echon printf("%s: %s", a:result.name, a:result.message)
		echo a:result.failure_msg
		echo a:result.log
	endif
endfunction


function! marching#test#run(name, ...)
	call s:print(marching#test#get(a:name), get(a:, 1))
endfunction


function! marching#test#run_all(...)
	let log = get(a:, 1)
	for name in keys(s:test)
		call marching#test#run(name, log)
	endfor
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
