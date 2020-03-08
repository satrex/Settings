" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
if v:version > 703 || v:version == 703 && has('patch1170')
  function! vital#_vim_gista#System#Cache#File#import() abort
    return map({'_vital_depends': '', 'dump': '', 'hash': '', 'load': '', 'new': '', '_vital_loaded': ''},  'function("s:" . v:key)')
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  execute join(['function! vital#_vim_gista#System#Cache#File#import() abort', printf("return map({'_vital_depends': '', 'dump': '', 'hash': '', 'load': '', 'new': '', '_vital_loaded': ''}, \"function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
  delfunction s:_SID
endif
" ___vital___
let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort
  let s:V = a:V
  let s:Prelude = a:V.import('Prelude')
  let s:String = a:V.import('Data.String')
  let s:File = a:V.import('System.File')
  let s:Path = a:V.import('System.Filepath')
  let s:Base = a:V.import('System.Cache.Base')
endfunction
function! s:_vital_depends() abort
  return [
        \ 'Prelude',
        \ 'Data.String',
        \ 'System.File',
        \ 'System.Filepath',
        \ 'System.Cache.Base',
        \]
endfunction

function! s:hash(cache_dir, str) abort
  " I'm not really sure if 150 is a best threshold for a path length.
  " But the value is for backward compatible behavior
  if len(a:cache_dir) + len(a:str) < 150
    let hash = substitute(substitute(
          \ a:str, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  else
    let hash = s:String.hash(a:str)
  endif
  return hash
endfunction

function! s:load(filename, ...) abort
  let default = get(a:000, 0, {})
  let raw = filereadable(a:filename) ? readfile(a:filename) : []
  if empty(raw)
    return default
  endif
  sandbox let obj = eval(join(raw, "\n"))
  return obj
endfunction

function! s:dump(filename, obj) abort
  call writefile([string(a:obj)], a:filename)
endfunction

let s:cache = {
      \ '__name__': 'file',
      \}
function! s:new(...) abort
  let options = get(a:000, 0, {})
  if !has_key(options, 'cache_dir')
    throw 'vital: System.Cache.File: No "cache_dir" option is specified.'
  endif
  " create a cache directory if it does not exist
  if !isdirectory(options.cache_dir)
    call mkdir(options.cache_dir, 'p')
  endif
  return extend(
        \ call(s:Base.new, a:000, s:Base),
        \ extend(options, deepcopy(s:cache))
        \)
endfunction

function! s:cache.cache_key(obj) abort
  let cache_key = s:Prelude.is_string(a:obj) ? a:obj : string(a:obj)
  let cache_key = s:hash(self.cache_dir, cache_key)
  return cache_key
endfunction
function! s:cache.get_cache_filename(name) abort
  let cache_key = self.cache_key(a:name)
  let filename = s:Path.join(self.cache_dir, cache_key)
  return filename
endfunction
function! s:cache.has(name) abort
  let filename = self.get_cache_filename(a:name)
  return filereadable(filename)
endfunction
function! s:cache.get(name, ...) abort
  let default = get(a:000, 0, '')
  let filename = self.get_cache_filename(a:name)
  return s:load(filename, default)
endfunction
function! s:cache.set(name, value) abort
  let filename = self.get_cache_filename(a:name)
  call s:dump(filename, a:value)
  call self.on_changed()
endfunction
function! s:cache.remove(name) abort
  let filename = self.get_cache_filename(a:name)
  if filereadable(filename)
    call delete(filename)
    call self.on_changed()
  endif
endfunction
function! s:cache.clear() abort
  call s:File.rmdir(self.cache_dir, 'r')
  call self.on_changed()
endfunction
function! s:cache.keys() abort
  let keys = split(glob(s:Path.join(self.cache_dir, '*'), 0), '\n')
  return map(keys, 'fnamemodify(v:val, ":t")')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
