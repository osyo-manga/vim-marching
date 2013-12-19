scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:log_data = ""
function! s:log(point, ...)
	if !g:marching_debug
		return
	endif
	let s:log_data .= strftime("%c", localtime()) . ' | ' . a:point . "\n"
	if a:0
		let s:log_data .= a:1 . "\n"
	endif
endfunction

function! marching#complete#log()
	return s:log_data
endfunction


function! marching#complete#popup_pos()
	return !pumvisible() ? ""
\		: g:marching_enable_auto_select ? "\<C-p>\<Down>"
\		: "\<C-p>"
endfunction



function! s:parse_complete_word(word)
	let complete_word = matchstr(a:word, '^.*\%(\s\|\.\|->\|::\)\ze.*$')
	let input         = matchstr(a:word, '^.*\%(\s\|\.\|->\|::\)\zs.*$')
	if empty(complete_word) && empty(input)
		return ["", a:word]
	endif
	return [complete_word, input]
endfunction



function! s:make_context(pos, bufnr)
	let line = get(getbufline(a:bufnr, a:pos[0]), 0)[ : a:pos[1]]
	let [complete_word, input] = s:parse_complete_word(line)
	return {
\		"complete_word" : complete_word,
\		"pos" : [a:pos[0], len(line) - len(input) + 1],
\		"bufnr" : a:bufnr
\	}
endfunction


function! s:make_current_context()
	return s:make_context(getpos(".")[1 : ], bufnr("%"))
endfunction



function! s:include_opt()
	let include_opt = join(map(filter(marching#get_include_dirs(), 'v:val !=# "."'), 'string(v:val)'), ' -I')
	if empty(include_opt)
		return ""
	endif
	return "-I" . include_opt
endfunction


function! s:clang_complete_command(cmd, file, line, col, args)
	if !filereadable(a:file)
		return ""
	endif
	return printf("%s -cc1 -std=c++11 -fsyntax-only %s -code-completion-at=%s:%d:%d %s", a:cmd, a:args, a:file, a:line, a:col, a:file)
endfunction


function! s:parse_complete_result(output)
	return map(split(a:output, "\n"), 'matchstr(v:val, ''COMPLETION: \zs.*\ze :'')')
endfunction


function! s:make_tempfile(filename, bufnr)
	let filename = substitute(a:filename, '\', '/', "g")
	if writefile(getbufline(a:bufnr, 1, "$"), filename) == -1
		return ""
	else
		return filename
	endif
endfunction


let s:complete_process = {
\	"process" : {},
\}

function! s:complete_process.clear()
	if !empty(self.process)
		call self.process.kill()
		let self.process = {}
	endif
	let self.context = {}
endfunction


function! s:complete_process.start(context)
	call self.clear()
	let tempfile = s:make_tempfile(fnamemodify(a:context.bufnr, ":p:h") . "/marching_complete_temp.cpp", a:context.bufnr)
	if !filereadable(tempfile)
		return
	endif

	let command = s:clang_complete_command(
\		get(b:, "marching_clang_command", g:marching_clang_command),
\		tempfile,
\		a:context.pos[0],
\		a:context.pos[1],
\		s:include_opt() . " " . get(b:, "marching_clang_command_option", g:marching_clang_command_option)
\	)
	call s:log("command", command)

	let self.process = reunions#process(command)

	let self.process.marching_context = a:context
	function! self.process.then(output)
		let result = s:parse_complete_result(a:output)
		call s:log("command result", string(result))
		if empty(result)
			echo "marching completion not found"
			return
		endif
		call s:on_complete_finish(self.marching_context, result)
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

function! marching#complete#update_complete_process()
	if has_key(s:complete_process.process, "update")
		call s:complete_process.process.update()
	endif
endfunction


let s:complete_cache = []
function! marching#complete#clear_complete_cache()
	let s:complete_cache = []
endfunction


function! s:on_complete_finish(context, result)
	call add(s:complete_cache, [a:context, a:result])
	echo "marching completion finish"
	call s:log("complete_finish")
	call feedkeys("\<Plug>(marching_start_omni_complete)")
endfunction

function! s:complete_start()
	echo "marching complete start"
	call s:log("complete_start")
	call s:complete_process.start(s:make_current_context())
endfunction

function! s:get_completion(context)
	for completion in s:complete_cache
		if completion[0] == a:context
			return completion
		endif
	endfor
	return []
endfunction


function! marching#complete#omnifunc(findstart, base)
	if a:findstart
		let completion = s:get_completion(s:make_current_context())
		if !empty(completion)
			return completion[0].pos[1] - 1
		endif
		call feedkeys("\<C-g>\<ESC>", 'n')
		call s:complete_start()
		if g:marching_enable_neocomplete
			return -1
		else
			return -3
		endif
	endif
	let completion = s:get_completion(s:make_current_context())
	if empty(completion)
		return []
	endif
	return filter(copy(completion[1]), 'v:val =~ "^".a:base')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
