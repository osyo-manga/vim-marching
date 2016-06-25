scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let g:marching#clang_command#options = get(g:, "marching#clang_command#options", {})

let s:Reunions = marching#vital().import("Reunions")


function! s:include_opt(...)
	let bufnr = get(a:, 1, bufnr("%"))
	let include_opt = join(map(filter(marching#get_include_dirs(bufnr), 'v:val !=# "."'), 'shellescape(v:val)'), ' -I')
	if empty(include_opt)
		return ""
	endif
	return "-I" . include_opt
endfunction

function! marching#clang_command#include_opt(...)
	let bufnr = get(a:, 1, bufnr("%"))
	return s:include_opt(bufnr)
endfunction


function! marching#clang_command#option(...)
	let bufnr = get(a:, 1, bufnr("%"))
	return getbufvar(bufnr, "marching_clang_command_default_options")
\		 . " "
\		 . s:include_opt(bufnr)
\		 . " "
\		 . get(g:marching#clang_command#options, getbufvar(bufnr, "&filetype"), "")
\		 . " "
\		 . get(getbufvar("%", ""), "marching_clang_command_option", g:marching_clang_command_option)
endfunction


function! s:clang_complete_command(cmd, file, line, col, args)
	if !filereadable(a:file)
		return ""
	endif
	return printf("%s %s -Xclang -code-completion-at=%s:%d:%d %s", a:cmd, a:args, a:file, a:line, a:col, a:file)
endfunction

function! marching#clang_command#clang_complete_command(...)
	return call("s:clang_complete_command", a:000)
endfunction


function! s:parse_complete_result_line(line)
	let pattern = '^COMPLETION: \(.\{-}\) : \(.\{-}\)$'
	if a:line !~ pattern
		return { "word" : matchstr(a:line, '^COMPLETION: \zs.*\ze$') }
	endif
	let parsed = matchlist(a:line, pattern)
	let result = {
\		"word" : parsed[1],
\		"abbr" : parsed[2],
\		"dup"  : g:marching_enable_dup
\	}
	let result.abbr = substitute(result.abbr, '\[#\(.\{-}\)#\]\(.*\)', '\2 -> \1', 'g')
	let result.abbr = substitute(result.abbr, '\[#\(.\{-}\)#\]', '\1', 'g')
	let result.abbr = substitute(result.abbr, '{#\(.\{-}\)#}', '\1', 'g')
	let result.abbr = substitute(result.abbr, '<#\(.\{-}\)#>', '\1', 'g')
" 	let result.abbr = substitute(result.abbr, '\(<#\|#>\)', '', 'g')
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
	let tempfile = marching#make_tempfile_from_buffer(a:context.bufnr)
	if !filereadable(tempfile)
		return
	endif

	let command = s:clang_complete_command(
\		get(b:, "marching_clang_command", g:marching_clang_command),
\		tempfile,
\		a:context.pos[0],
\		a:context.pos[1],
\		marching#clang_command#option(),
\	)
	call marching#print_log("clang_command command", command)
	let self.context = a:context

	let self.process = s:Reunions.process(command)

	let self.process.marching_context = a:context
	let self.process.parent = self
	function! self.process.then(output, ...)
		call marching#print_log("clang_command output", a:output)
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
		call marching#clear_cache(self.marching_context)
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
	if has_key(s:complete_process.process, "update")
		call s:complete_process.process.update()
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
	return 0
endfunction


function! marching#clang_command#check()
	call marching#clear_cache_all()
	call marching#clang_command#cancel()
	let old_time = g:marching_wait_time
	let context = marching#current_context()
	let old_debug = g:marching_debug
	let g:marching_debug = 1
	try
		let g:marching_wait_time = 999.0
		call marching#clang_command#complete(marching#current_context())
	finally
		let g:marching_wait_time = old_time
		let g:marching_debug = old_debug
	endtry
	call marching#clear_cache(context)
	return s:complete_process.result
endfunction


augroup plugin-marching
	autocmd!
	autocmd CursorHold,CursorHoldI * call s:Reunions.update_in_cursorhold(1)
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo

