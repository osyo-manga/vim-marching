scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:HTTP = vital#of("vim-marching").import("Web.HTTP")


function! s:bash(code)
	let query = '{
	\  "code": "' . escape(a:code, '"') .  '",
	\  "compiler": "bash",
	\  "options": "",
	\  "compiler-option-raw": ""
	\}'
	return query
endfunction


function! s:post_wandbox(query)
	let result = webapi#http#post("http://melpon.org/wandbox/api/compile.json",
\		a:query,
\		{ "Content-type" : "application/json" },
\	)
	call marching#print_log("sync_wandbox post result", result)
	let content = webapi#json#decode(result.content)
	return content.program_output
endfunction


function! s:wandbox_completion(source, line, col, option, filename)
	let code = join([
\		printf("cat <<'EOT'> %s", a:filename),
\		a:source,
\		"EOT",
\		printf("/usr/local/llvm-head/bin/clang++ -cc1  -I/usr/local/llvm-head/lib/clang/3.5/include -I/usr/include -I/usr/local/libcxx-head/include/c++/v1 -stdlib=libc++ -I/usr/local/boost-1.55.0/include -I/usr/local/sprout -fsyntax-only %s -code-completion-at=%s:%d:%d %s", a:option, a:filename, a:line, a:col, a:filename),
\	], "\n")
	call marching#print_log("sync_wandbox bash code", code)

	let query = s:bash(code)
	call marching#print_log("sync_wandbox post query", query)
	return s:post_wandbox(s:bash(code))
endfunction



function! marching#sync_wandbox#complete(context)
	echo "marching completion start"

	let source = join(getline(1, "$"), "\n")
	let line = a:context.pos[0]
	let col  = a:context.pos[1]
	let option = get(b:, "marching_clang_command_option", g:marching_clang_command_option)
	if has("reltime")
		let filename = printf("marching_vim_prog_%s.cpp", join(split(reltimestr(reltime()), '\.'), "_"))
	else
		let filename = printf("marching_vim_prog_%d.cpp", localtime())
	endif

	let result = s:wandbox_completion(source, line, col, "", filename)

	redraw
	echo "marching completion finish"
	return marching#clang_command#parse_complete_result(result)

	try
		let command = marching#clang_command#clang_complete_command(
\			get(b:, "marching_clang_command", g:marching_clang_command),
\			tempfile,
\			a:context.pos[0],
\			a:context.pos[1],
\				get(b:, "marching_clang_command_default_options", '-cc1 -fsyntax-only')
\			  . " "
\			  . marching#clang_command#include_opt()
\			  . " "
\			  . get(b:, "marching_clang_command_option", g:marching_clang_command_option)
\		)
		call marching#print_log("sync_clang_command command", command)

		let has_vimproc = 0
		silent! let has_vimproc = vimproc#version()
		if has_vimproc
			let result = vimproc#system(command)
		else
			let result = system(command)
		endif

		redraw
		echo "marching completion finish"
		return marching#clang_command#parse_complete_result(result)
	finally
		call delete(tempfile)
	endtry
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
