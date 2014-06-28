" original source code
" mattn/webapi-vim : https://github.com/mattn/webapi-vim
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:_vital_loaded(V)
	let s:V = a:V
	let s:Process  = s:V.import("Reunions.Process")
	let s:HTTP = s:V.import("Web.HTTP")
endfunction


function! s:_vital_depends()
	return [
\		"Reunions.Process",
\		"Web.HTTP",
\	]
endfunction


function! s:build_get_command(url, ...)
  let getdata = a:0 > 0 ? a:000[0] : {}
  let headdata = a:0 > 1 ? a:000[1] : {}
"   let follow = a:0 > 2 ? a:000[2] : 1
  let follow =  1
  let url = a:url
  let getdatastr = s:HTTP.encodeURI(getdata)
  if strlen(getdatastr)
    let url .= "?" . getdatastr
  endif
  if executable('curl')
    let command = printf('curl %s -s -k -i', follow ? '-L' : '')
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " -H " . quote . key . ": " . headdata[key] . quote
      endif
    endfor
    let command .= " ".quote.url.quote
"     let res = s:system(command)
    return command
  elseif executable('wget')
    let command = printf('wget -O- --save-headers --server-response -q %s', follow ? '-L' : '')
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " --header=" . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " --header=" . quote . key . ": " . headdata[key] . quote
      endif
    endfor
    let command .= " ".quote.url.quote
"     let res = s:system(command)
    return command
  else
    throw "require `curl` or `wget` command"
  endif
endfunction


function! s:parse_result(result)
  let res = a:result
  let follow =  1
  if follow != 0
    while res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established' || res =~ '^HTTP/1\.\d 100 Continue'
      let pos = stridx(res, "\r\n\r\n")
      if pos != -1
        let res = strpart(res, pos+4)
      else
        let pos = stridx(res, "\n\n")
        let res = strpart(res, pos+2)
      endif
    endwhile
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = strpart(res, pos+4)
  else
    let pos = stridx(res, "\n\n")
    let content = strpart(res, pos+2)
  endif
  let header = split(res[:pos-1], '\r\?\n')
  let matched = matchlist(get(header, 0), '^HTTP/1\.\d\s\+\(\d\+\)\s\+\(.*\)')
  if !empty(matched)
    let [status, message] = matched[1 : 2]
    call remove(header, 0)
  else
    if v:shell_error || len(matched)
      let [status, message] = ['500', "Couldn't connect to host"]
    else
      let [status, message] = ['200', 'OK']
    endif
  endif
  return {
  \ "status" : status,
  \ "message" : message,
  \ "header" : header,
  \ "content" : content
  \}
endfunction


function! s:make_get_process(...)
	let cmd = call("s:build_get_command", a:000)
	let process = s:Process.make(cmd)
	function! process._then(output, ...)
		if !has_key(self, "then")
			return
		endif
		return call(self.then, [s:parse_result(a:output)] + a:000, self)
	endfunction
	
	function! process.get()
		call self.wait()
		return s:parse_result(self.as_result().body)
	endfunction

	return process
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
