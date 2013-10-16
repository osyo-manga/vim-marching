scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! marching#popup_pos()
	return !pumvisible() ? ""
\		: g:marching_enable_auto_select ? "\<C-p>\<Down>"
\		: "\<C-p>"
endfunction


let s:log_data = ""
function! marching#print_log(point, ...)
	if !g:marching_debug
		return
	endif
	let s:log_data .= strftime("%c", localtime()) . ' | ' . a:point . "\n"
	if a:0
		let s:log_data .= a:1 . "\n"
	endif
endfunction


function! marching#log()
	return s:log_data
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
\		"bufnr" : a:bufnr,
\		"keyword" : matchstr(complete_word, '\s*\zs.*')
\	}
endfunction


function! s:current_context()
	return s:make_context(getpos(".")[1 : ], bufnr("%"))
endfunction


function! marching#current_context()
	return s:current_context()
endfunction

function! s:get_current_cache()
	return get(b:, "marching_cache", {})
endfunction


function! s:get_cache(context)
	return get(s:get_current_cache(), a:context.keyword, [])
endfunction


function! marching#clear_cache_all()
	let b:marching_cache = {}
endfunction


function! marching#clear_cache(context)
	return remove(s:get_current_cache(), a:context.keyword)
endfunction


function! s:add_cache(context, completion)
	if !exists("b:marching_cache")
		let b:marching_cache = {}
	endif
	let b:marching_cache[a:context.keyword] = a:completion
endfunction


function! marching#complete(findstart, base)
	if a:findstart
		let context = s:current_context()
		let completion = s:get_cache(context)
		if !empty(completion)
			return context.pos[1] - 1
		endif

		let result = marching#clang_command#complete(context)
		if !empty(result)
			call s:add_cache(context, result)
			return context.pos[1] - 1
		endif

		if g:marching_enable_neocomplete
			return -1
		else
			return -3
		endif
	endif
	let completion = s:get_cache(s:current_context())
	if empty(completion)
		return []
	endif
	return filter(copy(completion), 'v:val =~ "^".a:base')
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
