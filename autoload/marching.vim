scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim



function! marching#complete(findstart, base)
	return marching#complete#omnifunc(a:findstart, a:base)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
