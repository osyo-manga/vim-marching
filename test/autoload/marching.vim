
" test data
if 0
	x.mami
	::
::
	homu.mami;  homu.mado;
endif



function! s:test_make_context()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching.vim")
	let bufnr = bufnr("test/autoload/marching.vim")
	
	OwlCheck s:make_context([4, 6], bufnr).pos == [4, 4]
	OwlCheck s:make_context([4, 6], bufnr).complete_word == "	x."
	OwlCheck s:make_context([4, 6], bufnr).bufnr == bufnr
	OwlCheck s:make_context([5, 4], bufnr).pos == [5, 4]
	OwlCheck s:make_context([5, 4], bufnr).complete_word == "	::"
	OwlCheck s:make_context([5, 4], bufnr).bufnr == bufnr
	OwlCheck s:make_context([6, 3], bufnr).pos == [6, 3]
	OwlCheck s:make_context([6, 3], bufnr).complete_word == "::"
	OwlCheck s:make_context([7, 8], bufnr).pos == [7, 7]
	OwlCheck s:make_context([7, 8], bufnr).complete_word == "	homu."
	OwlCheck s:make_context([7, 22], bufnr).pos == [7, 19]
	OwlCheck s:make_context([7, 22], bufnr).complete_word == "	homu.mami;  homu."
endfunction




function! s:test_parse_keyword()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching.vim")

	OwlCheck s:get_keyword("homu; mami") is# ""
	OwlCheck s:get_keyword("hoge.value") ==# "hoge."
	OwlCheck s:get_keyword("hoge.") ==# "hoge."
	OwlCheck s:get_keyword("std::has_xxx") ==# "std::"
	OwlCheck s:get_keyword("std::") ==# "std::"
	OwlCheck s:get_keyword("func(std::") ==# "std::"
	OwlCheck s:get_keyword("func(hoge.val") ==# "hoge."
	OwlCheck s:get_keyword("func(a, hoge.val") ==# "hoge."
	OwlCheck s:get_keyword("::has_xxx") ==# "::"
	OwlCheck s:get_keyword("*this->") ==# "*this->"
	OwlCheck s:get_keyword("->value") ==# ""
	OwlCheck s:get_keyword(".value") ==# ""
	OwlCheck s:get_keyword("::") ==# "::"
	OwlCheck s:get_keyword("aaa;	boost::lambda::_1") ==# "boost::lambda::"
	OwlCheck s:get_keyword("aaa; hoge<boost::lambda::_1") ==# "boost::lambda::"
	OwlCheck s:get_keyword("	hoge.value") ==# "hoge."
	OwlCheck s:get_keyword("n; hoge.value") ==# "hoge."
	OwlCheck s:get_keyword("value, hoge.value") ==# "hoge."
	OwlCheck s:get_keyword("a, b).value") ==# "a,b)."
	OwlCheck s:get_keyword(" 	a, b).value") ==# "a,b)."
	OwlCheck s:get_keyword(" 	a, b>::type") ==# "a,b>::"
	OwlCheck s:get_keyword("a, b).value->hoge") ==# "a,b).value->"
	OwlCheck s:get_keyword("x; func(a, b).value->hoge") ==# "func(a,b).value->"
	OwlCheck s:get_keyword("n; hoge).value") ==# "hoge)."
	OwlCheck s:get_keyword(";  BOOST_") ==# ""
	OwlCheck s:get_keyword("}  std::stri") ==# "std::"
	
	OwlCheck s:get_keyword("func().va") ==# "func()."
	OwlCheck s:get_keyword("func(a, b, c).va") ==# "func(a,b,c)."
	OwlCheck s:get_keyword("x; func (). ") ==# "func()."
	OwlCheck s:get_keyword("x;func (). ") ==# "func()."
	OwlCheck s:get_keyword("  x; func (). ") ==# "func()."
	OwlCheck s:get_keyword("  x; hoge[1](). ") ==# "hoge[1]()."
	OwlCheck s:get_keyword("  x; hoge[1, 2](). ") ==# "hoge[1,2]()."
endfunction


function! s:test_remove_comment()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching.vim")

	OwlCheck s:remove_comment("/*hoge*/ homu /*mami*/ an // mado") ==# '  homu   an '
	OwlCheck s:remove_comment("/*hoge \n */homu/*mami*/ // mado\n // mami\nmado") =~ ' homu  \n \nmado'
endfunction

