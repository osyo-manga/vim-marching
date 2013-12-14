scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:extensions = {
\	"c"   : "c",
\	"cpp" : "cpp",
\}

function! marching#extension(filetype)
	return get(extend(s:extensions, get(g:, "marching_extension", {})), a:filetype, a:filetype)
endfunction


function! s:make_tempfile(filename, bufnr)
	let filename = substitute(a:filename, '\', '/', "g")
	if writefile(getbufline(a:bufnr, 1, "$"), filename) == -1
		return ""
	else
		return filename
	endif
endfunction


function! marching#make_tempfile_from_buffer(bufnr)
	let ext = marching#extension(getbufvar(a:bufnr, "&filetype"))
	let tempfile = s:make_tempfile(fnamemodify(bufname(a:bufnr), ":p:h") . "/marching_complete_temp." . ext, a:bufnr)
	return tempfile
endfunction


function! marching#get_included_files(bufnr)
	return filter(map(getline(a:bufnr, 1, "$"), 'matchstr(v:val, ''^\s*#\s*include\s*[<"]\zs.*\ze[">]'')'), '!empty(v:val)')
endfunction


function! marching#get_include_dirs()
	return filter(split(&path, ',') + g:marching_include_paths, 'isdirectory(v:val) && v:val !~ ''\./''')
endfunction


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
	let s:log_data .= "---- " . strftime("%c", localtime()) . ' ---- | ' . a:point . "\n"
	if a:0
		let s:log_data .= (type(a:1) == type("") ? a:1 : string(a:1)) . "\n"
	endif
endfunction


function! marching#log()
	return s:log_data
endfunction


function! marching#clear_log()
	let s:log_data = ""
endfunction


function! s:get_bracket(char)
	return get({
\		')' : '(',
\		'>' : '<',
\		']' : '[',
\		'}' : '{',
\	}, a:char, a:char)
endfunction


function! s:remove_comment(str)
	let result = substitute(a:str, '\/\*.\{-}\*\/', ' ', "g")
	let result = substitute(result, '\/\/.\{-}\($\|\n\)', '\1', "g")
	return result
endfunction


function! s:parse_keyword(str)
	let target = matchstr(a:str, '\zs.*\(\.\|->\|::\)\ze.*')
	if empty(target) || target =~ '^\(\.\|->\)$'
		return ""
	endif
	if target ==# '::'
		return "::"
	endif
	let result = ""
	let indent = { '(' : 0, '[' : 0, '<' : 0, '{' : 0 }

	" remove () space
	let target = substitute(target, '\w\zs\s\+\ze[([{<]', '', "g")

	for char in reverse(split(target, '\zs'))
		if char ==# ';'
			return result
		endif
		if char =~ '[,}[:blank:]]'
\		&& !indent['(']
\		&& !indent['[']
\		&& !indent['<']
\		&& !indent['{']
			return result
		endif
		if char =~ '[)>}\]]'
			let indent[s:get_bracket(char)] += 1
		endif
		if char =~ '[(<{[]'
			if indent[char] == 0
				return result
			else
				let indent[char] -= 1
			endif
		endif
		let result = char . result
	endfor
	return result
endfunction


function! s:get_keyword(line)
	let result = s:parse_keyword(a:line)
	return substitute(result, '\s', '', "g")
endfunction

" echo s:get_keyword("10, std::")
" echo s:get_keyword("con std::")

function! s:parse_complete_word(word)
	let complete_word = matchstr(a:word, '^.*\%(\s\|\.\|->\|::\)\ze.*$')
	let input         = matchstr(a:word, '^.*\%(\s\|\.\|->\|::\)\zs.*$')
	if empty(complete_word) && empty(input)
		return ["", a:word]
	endif
	return [complete_word, input]
endfunction


function! s:make_context(pos, bufnr)
	let line = get(getbufline(a:bufnr, a:pos[0]), 0)[ : a:pos[1]-2]
	let [complete_word, input] = s:parse_complete_word(line)

	let keyword_line = s:remove_comment(join(getbufline(bufnr("%"), line(".") - 5 < 1 ? 1 : line(".") - 5, line(".") - 1), "\n") . "\n"  . line)
	let keyword_line = substitute(keyword_line, '\n', ' ', 'g')
	return {
\		"complete_word" : complete_word,
\		"pos" : [a:pos[0], len(line) - len(input) + 1],
\		"bufnr" : a:bufnr,
\		"keyword" : s:get_keyword(keyword_line)
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
	if empty(a:context.keyword)
		return
	endif
	let b:marching_cache[a:context.keyword] = a:completion
endfunction


function! marching#check_complete_always()
	if g:marching_enable_refresh_always
		if exists("*marching#" . g:marching_backend . "#update_complete_process")
			call marching#{g:marching_backend}#update_complete_process()
		endif
		if get(s:, "complete_started", 0)
\		&& pumvisible()
			call feedkeys("\<Plug>(marching_start_omni_complete)")
		endif
	endif
endfunction


function! marching#complete(findstart, base)
	let s:complete_started = 1
	if a:findstart
		let s:completion = []
		let s:context = s:current_context()
		let s:completion = s:get_cache(s:context)
		if !empty(s:completion)
			return s:context.pos[1] - 1
		endif

		let s:completion = marching#{g:marching_backend}#complete(s:context)
		if !empty(s:completion)
			call s:add_cache(s:context, s:completion)
			return s:context.pos[1] - 1
		endif

		if g:marching_enable_neocomplete
			return -1
		else
			return -3
		endif
	endif
" 	let completion = s:get_cache(s:context)
	let completion = s:completion
	if empty(completion)
		return []
	endif

	let result = deepcopy(filter(copy(completion), 'v:val.word =~ "^".a:base'))
	let len = max(map(copy(result), "len(v:val.word)"))
	if !g:marching_enable_refresh_always
		let len = min([len, 10])
	endif
	let format = "%-" . len . "s : %s"
	for _ in result
		let _.abbr = printf(format, _.word, get(_, "abbr"))
	endfor
	return result
endfunction


augroup plugin-marching
	autocmd!
	autocmd CompleteDone * let s:complete_started = 0
augroup END




let &cpo = s:save_cpo
unlet s:save_cpo
