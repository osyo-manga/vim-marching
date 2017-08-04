scriptencoding utf-8
if exists('g:loaded_marching')
  finish
endif
let g:loaded_marching = 1

let s:save_cpo = &cpo
set cpo&vim


let g:marching_clang_command         = get(g:, "marching_clang_command", "clang")
let g:marching_clang_command_option  = get(g:, "marching_clang_command_option", "")
let g:marching_include_paths         = get(g:, "marching_include_paths", [])
let g:marching_wait_time             = get(g:, "marching_wait_time", 0.5)
let g:marching_enable_auto_select    = get(g:, "marching_enable_auto_select", 0)
let g:marching_enable_neocomplete    = get(g:, "marching_enable_neocomplete", 0)
let g:marching_debug                 = get(g:, "marching_debug", 0)
let g:marching_backend               = get(g:, "marching_backend", "clang_command")
let g:marching_enable_refresh_always = get(g:, "marching_enable_refresh_always", 0)
let g:marching_enable_dup = get(g:, "marching_enable_dup", 1)
" let g:marching_clang_command_updatetime =


inoremap <silent> <Plug>(marching_start_omni_complete)
   \ <C-x><C-o><C-r>=marching#complete#popup_pos()<CR>


function! s:clear_cache()
	call marching#clear_cache(marching#current_context())
	call marching#clang_command#cancel()
	return pumvisible() ? "\<C-x>" : ""
endfunction


inoremap <silent> <Plug>(marching_force_start_omni_complete)
   \ <C-r>=<SID>clear_cache()<CR><C-x><C-o><C-r>=marching#complete#popup_pos()<CR>


function! s:clear_cache()
	call marching#clear_cache_all()
	call marching#clang_command#cancel()
	return ""
endfunction

command! -bar MarchingBufferClearCache call s:clear_cache()

command! -bar MarchingDebugLog echo marching#log()
command! -bar MarchingDebugClearLog call marching#clear_log()
command! -bar MarchingEnableDebug  let g:marching_debug = 1
command! -bar MarchingDisableDebug let g:marching_debug = 0

command! -bar MarchingDebugCheck call marching#clang_command#check() | MarchingDebugLog
command! -bar -bang MarchingDebugTest call marching#test#run_all("<bang>" == "!")


let &cpo = s:save_cpo
unlet s:save_cpo
