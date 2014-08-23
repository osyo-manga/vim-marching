

function! s:test_parse_complete_result_line()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching/clang_command.vim")
	OwlCheck s:parse_complete_result_line("COMPLETION: func : [#void#]func()").word ==# "func"
	OwlCheck s:parse_complete_result_line("COMPLETION: func : [#void#]func()").abbr ==# "func() -> void"
	OwlCheck s:parse_complete_result_line("COMPLETION: func : [#void#]func(<#int#>)").abbr ==# "func(int) -> void"
	OwlCheck s:parse_complete_result_line("COMPLETION: __FUNCTION__").word ==# "__FUNCTION__"
	OwlCheck s:parse_complete_result_line("COMPLETION: at : [#const_reference#]at(<#size_type __n#>)[# const#]").word ==# "at"
	OwlCheck s:parse_complete_result_line("COMPLETION: at : [#const_reference#]at(<#size_type __n#>)[# const#]").abbr ==# "at(size_type __n) const -> const_reference"
	OwlCheck s:parse_complete_result_line('COMPLETION: operator"" : [#chrono::hours#]operator "" h(<#unsigned long long __h#>)').abbr ==# 'operator "" h(unsigned long long __h) -> chrono::hours'
endfunction


