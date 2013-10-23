

function! s:test_parse_complete_result_line()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching/clang_command.vim")
	OwlCheck s:parse_complete_result_line("COMPLETION: func : [#void#]func()").word ==# "func"
	OwlCheck s:parse_complete_result_line("COMPLETION: func : [#void#]func()").abbr ==# "func() -> void"
	OwlCheck s:parse_complete_result_line("COMPLETION: func : [#void#]func(<#int#>)").abbr ==# "func(int) -> void"
	OwlCheck s:parse_complete_result_line("COMPLETION: __FUNCTION__").word ==# "__FUNCTION__"
endfunction


