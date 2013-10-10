
" test date
if 0
	x.mami
	::
::
	homu.mami;  homu.mado;
endif



function! s:test_parse_complete_word()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching/complete.vim")
	OwlCheck s:parse_complete_word("mami.mado") == ["mami.", "mado"]
	OwlCheck s:parse_complete_word("mami->mado") == ["mami->", "mado"]
	OwlCheck s:parse_complete_word("mami::mado") == ["mami::", "mado"]
	OwlCheck s:parse_complete_word("mami::mado->homu") == ["mami::mado->", "homu"]
	OwlCheck s:parse_complete_word("mami") == ["", "mami"]
	OwlCheck s:parse_complete_word("mami->") == ["mami->", ""]
	OwlCheck s:parse_complete_word(".mado") == [".", "mado"]
	OwlCheck s:parse_complete_word("::homu") == ["::", "homu"]
	OwlCheck s:parse_complete_word("	.mado") == ["	.", "mado"]
	OwlCheck s:parse_complete_word("	::mado") == ["	::", "mado"]
	OwlCheck s:parse_complete_word("	") == ["	", ""]
	OwlCheck s:parse_complete_word("::") == ["::", ""]
	OwlCheck s:parse_complete_word("homu;	mami") == ["homu;	", "mami"]
	OwlCheck s:parse_complete_word("homu;	mami->") == ["homu;	mami->", ""]
	OwlCheck s:parse_complete_word("homu;	mami->mado") == ["homu;	mami->", "mado"]
endfunction


function! s:test_make_context()
	let owl_SID = owl#filename_to_SID("vim-marching/autoload/marching/complete.vim")
	let bufnr = bufnr("test/autoload/complete.vim")
	
	OwlCheck s:make_context([4, 6], bufnr).pos == [4, 4]
	OwlCheck s:make_context([4, 6], bufnr).complete_word == "	x."
	OwlCheck s:make_context([4, 6], bufnr).bufnr == 7
	OwlCheck s:make_context([5, 4], bufnr).pos == [5, 4]
	OwlCheck s:make_context([5, 4], bufnr).complete_word == "	::"
	OwlCheck s:make_context([5, 4], bufnr).bufnr == 7
	OwlCheck s:make_context([6, 3], bufnr).pos == [6, 3]
	OwlCheck s:make_context([6, 3], bufnr).complete_word == "::"
	OwlCheck s:make_context([7, 8], bufnr).pos == [7, 7]
	OwlCheck s:make_context([7, 8], bufnr).complete_word == "	homu."
	OwlCheck s:make_context([7, 22], bufnr).pos == [7, 19]
	OwlCheck s:make_context([7, 22], bufnr).complete_word == "	homu.mami;  homu."
endfunction



