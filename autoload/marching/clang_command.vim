scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:include_opt()
	let include_opt = join(filter(marching#get_include_dirs(), 'v:val !=# "."'), ' -I')
	if empty(include_opt)
		return ""
	endif
	return "-I" . include_opt
endfunction

function! marching#clang_command#include_opt()
	return s:include_opt()
endfunction


function! s:clang_complete_command(cmd, file, line, col, args)
	if !filereadable(a:file)
		return ""
	endif
	return printf("%s %s -code-completion-at=%s:%d:%d %s", a:cmd, a:args, a:file, a:line, a:col, a:file)
endfunction

function! marching#clang_command#clang_complete_command(...)
	return call("s:clang_complete_command", a:000)
endfunction


function! s:parse_complete_result_line(line)
	let pattern = '^COMPLETION: \(.*\) : \(.*\)$'
	if a:line !~ pattern
		return { "word" : matchstr(a:line, '^COMPLETION: \zs.*\ze$') }
	endif
	let result = eval(substitute(a:line, pattern, '{ "word" : "\1", "abbr" : "\2", "dup" : 1 }', ""))
	let result.abbr = substitute(result.abbr, '\[#\(.*\)#\]\(.*\)', '\2 -> \1', 'g')
	let result.abbr = substitute(result.abbr, '\(<#\|#>\)', '', 'g')
	return result
endfunction


function! s:parse_complete_result(output)
	return map(split(a:output, "\n"), 's:parse_complete_result_line(v:val)')
endfunction

function! marching#clang_command#parse_complete_result(output)
	return s:parse_complete_result(a:output)
endfunction

function! s:make_tempfile(filename, bufnr)
	let filename = substitute(a:filename, '\', '/', "g")
	if writefile(getbufline(a:bufnr, 1, "$"), filename) == -1
		return ""
	else
		return filename
	endif
endfunction

function! marching#clang_command#make_tempfile(filename, bufnr)
	return s:make_tempfile(a:filename, a:bufnr)
endfunction



let s:complete_process = {
\	"process" : {},
\}


function! s:complete_process.clear()
	if !empty(self.process)
		call self.process.kill()
		let self.process = {}
	endif
	if has_key(self, "result")
		unlet self.result
	endif
	if has_key(self, "context")
		unlet self.context
	endif
endfunction


function! s:complete_process.start(context)
	echo "marching completion start"
	call marching#print_log("clang_command start")
	call self.clear()
	let ext = filereadable(bufname(a:context.bufnr)) ? fnamemodify(bufname(a:context.bufnr), ":e") : &filetype
	let tempfile = s:make_tempfile(fnamemodify(bufname(a:context.bufnr), ":p:h") . "/marching_complete_temp." . ext, a:context.bufnr)
	if !filereadable(tempfile)
		return
	endif

	let command = s:clang_complete_command(
\		get(b:, "marching_clang_command", g:marching_clang_command),
\		tempfile,
\		a:context.pos[0],
\		a:context.pos[1],
\			get(b:, "marching_clang_command_default_options", '-cc1 -fsyntax-only')
\		  . " "
\		  . s:include_opt()
\		  . " "
\		  . get(b:, "marching_clang_command_option", g:marching_clang_command_option)
\	)
	call marching#print_log("clang_command command", command)
	let self.context = a:context

	let self.process = reunions#process(command)

	let self.process.marching_context = a:context
	let self.process.parent = self
	function! self.process.then(output)
		let result = s:parse_complete_result(a:output)
		call marching#print_log("clang_command result", string(result))
		if empty(result)
			echo "marching completion not found"
			let self.parent.result = []
			return
		endif
		echo "marching completion finish"
		let self.parent.result = result
		call marching#print_log("clang_command finish")
		call feedkeys("\<Plug>(marching_start_omni_complete)")
	endfunction

	let self.process.tempfile = tempfile
	let self.process.base_kill = self.process.kill
	function! self.process.kill()
		call delete(self.tempfile)
		call self.base_kill()
	endfunction
	if g:marching_wait_time != 0.0
		call self.process.wait_for(g:marching_wait_time)
	endif
endfunction


function! marching#clang_command#update_complete_process()
	if has_key(s:complete_process.process, "apply")
		call s:complete_process.process.apply()
	endif
endfunction


function! marching#clang_command#cancel()
	call s:complete_process.clear()
endfunction

function! marching#clang_command#complete(context)
	if has_key(s:complete_process, "result")
\	&& has_key(s:complete_process, "context")
\	&& s:complete_process.context.keyword ==# a:context.keyword
		return s:complete_process.result
	endif
	call feedkeys("\<C-g>\<ESC>", 'n')
	call s:complete_process.start(a:context)
	return []
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

