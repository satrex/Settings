autocmd!

" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
  finish
endif

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
 set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file
endif
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands

"----------------------------------------
" システム設定
"----------------------------------------
"mswin.vimを読み込む
"source $VIMRUNTIME/mswin.vim
"behave mswin

"ファイルの上書きの前にバックアップを作る/作らない
"set writebackupを指定してもオプション 'backup' がオンでない限り、
"バックアップは上書きに成功した後に削除される。
set nowritebackup
"バックアップ/スワップファイルを作成する/しない
"set nobackup
"set noswapfile
"viminfoを作成しない
"set viminfo=
"クリップボードを共有
set clipboard+=unnamed
"8進数を無効にする。<C-a>,<C-x>に影響する
set nrformats-=octal
"キーコードやマッピングされたキー列が完了するのを待つ時間(ミリ秒)
set timeoutlen=3500
"編集結果非保存のバッファから、新しいバッファを開くときに警告を出さない
set hidden
"ヒストリの保存数
set history=100000
"日本語の行の連結時には空白を入力しない
set formatoptions+=mM
"Visual blockモードでフリーカーソルを有効にする
set virtualedit=block
"カーソルキーで行末／行頭の移動可能に設定
set whichwrap=b,s,[,],<,>,h,l
"バックスペースでインデントや改行を削除できるようにする
set backspace=indent,eol,start
"□や○の文字があってもカーソル位置がずれないようにする
set ambiwidth=double
"コマンドライン補完するときに強化されたものを使う
set wildmenu wildmode=list:full
" sudo権限で上書き保存する
cmap w!! w !sudo tee > /dev/null %

"マウスを有効にする
if has('mouse')
  set mouse=a
endif
"pluginを使用可能にする
filetype plugin indent on

"----------------------------------------
" 検索
"----------------------------------------
"検索の時に大文字小文字を区別しない
"ただし大文字小文字の両方が含まれている場合は大文字小文字を区別する
set ignorecase
set smartcase
"検索時にファイルの最後まで行ったら最初に戻る
set wrapscan
"インクリメンタルサーチ
set incsearch
"検索文字の強調表示
set hlsearch
"w,bの移動で認識する文字
"set iskeyword=a-z,A-Z,48-57,_,.,-,>
"vimgrep をデフォルトのgrepとする場合internal
"set grepprg=internal

"----------------------------------------
" 表示設定
"----------------------------------------
"スプラッシュ(起動時のメッセージ)を表示しない
set shortmess+=I
"エラー時の音とビジュアルベルの抑制(gvimは.gvimrcで設定)
set noerrorbells
set novisualbell
set visualbell t_vb=
"マクロ実行中などの画面再描画を行わない
"set lazyredraw
"Windowsでディレクトリパスの区切り文字表示に / を使えるようにする
set shellslash
"行番号表示
set number
"括弧の対応表示時間
set showmatch matchtime=1
"タブを設定
set ts=2 sw=4 sts=4
set expandtab
"自動的にインデントする
set autoindent
set smartindent
"インデントの設定
set cinoptions+=:0
"タイトルを表示
set title
"コマンドラインの高さ (gvimはgvimrcで指定)
set cmdheight=2
set laststatus=2
"コマンドをステータス行に表示
set showcmd
"画面最後の行をできる限り表示する
set display=lastline
"Tab、行末の半角スペースを明示的に表示する
"set list
"set listchars=tab:^\ ,trail:~
" ハイライトを有効にする
syntax on
set nohlsearch
set cursorline


"色テーマ設定
"gvimの色テーマは.gvimrcで指定する
"colorscheme mycolor

"----------------------------------------
" タブ表示設定
"----------------------------------------
" Anywhere SID.
function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

" Set tabline.
function! s:my_tabline()  "{{{
  let s = ''
  for i in range(1, tabpagenr('$'))
    let bufnrs = tabpagebuflist(i)
    let bufnr = bufnrs[tabpagewinnr(i) - 1]  " first window, first appears
    let no = i  " display 0-origin tabpagenr.
    let mod = getbufvar(bufnr, '&modified') ? '!' : ' '
    let title = fnamemodify(bufname(bufnr), ':t')
    let title = '[' . title . ']'
    let s .= '%'.i.'T'
    let s .= '%#' . (i == tabpagenr() ? 'TabLineSel' : 'TabLine') . '#'
    let s .= no . ':' . title
    let s .= mod
    let s .= '%#TabLineFill# '
  endfor
  let s .= '%#TabLineFill#%T%=%#TabLine#'
  return s
endfunction "}}}
let &tabline = '%!'. s:SID_PREFIX() . 'my_tabline()'
set showtabline=2 " 常にタブラインを表示

" The prefix key.
nnoremap    [Tag]   <Nop>
nmap    t [Tag]
" Tab jump
for n in range(1, 9)
  execute 'nnoremap <silent> [Tag]'.n  ':<C-u>tabnext'.n.'<CR>'
endfor
" t1 で1番左のタブ、t2 で1番左から2番目のタブにジャンプ

map <silent> [Tag]c :tablast <bar> tabnew<CR>
" tc 新しいタブを一番右に作る
map <silent> [Tag]x :tabclose<CR>
" tx タブを閉じる
map <silent> [Tag]n :tabnext<CR>
" tn 次のタブ
map <silent> [Tag]p :tabprevious<CR>
" tp 前のタブ




""""""""""""""""""""""""""""""
"ステータスラインに文字コードやBOM、16進表示等表示
"iconvが使用可能の場合、カーソル上の文字コードをエンコードに応じた表示にするFencB()を使用
""""""""""""""""""""""""""""""
if has('iconv')
  set statusline=%<%f\ %m\ %r%h%w%{'['.(&fenc!=''?&fenc:&enc).(&bomb?':BOM':'').']['.&ff.']'}%=[0x%{FencB()}]\ (%v,%l)/%L%8P\ 

else
  set statusline=%<%f\ %m\ %r%h%w%{'['.(&fenc!=''?&fenc:&enc).(&bomb?':BOM':'').']['.&ff.']'}%=\ (%v,%l)/%L%8P\ 

endif

function! FencB()
  let c = matchstr(getline('.'), '.', col('.') - 1)
  let c = iconv(c, &enc, &fenc)
  return s:Byte2hex(s:Str2byte(c))
endfunction

function! s:Str2byte(str)
  return map(range(len(a:str)), 'char2nr(a:str[v:val])')
endfunction

function! s:Byte2hex(bytes)
  return join(map(copy(a:bytes), 'printf("%02X", v:val)'), '')
endfunction

"----------------------------------------
" diff/patch
"----------------------------------------
"diffの設定
if has('win32') || has('win64')
  set diffexpr=MyDiff()
  function! MyDiff()
    let opt = '-a --binary '
    if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
    if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
    let arg1 = v:fname_in
    if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
    let arg2 = v:fname_new
    if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
    let arg3 = v:fname_out
    if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
    silent execute '!diff ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3
  endfunction
endif

"現バッファの差分表示(変更箇所の表示)
command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis
"ファイルまたはバッファ番号を指定して差分表示。#なら裏バッファと比較
command! -nargs=? -complete=file Diff if '<args>'=='' | browse vertical diffsplit|else| vertical diffsplit <args>|endif
"パッチコマンド
set patchexpr=MyPatch()
function! MyPatch()
   :call system($VIM."\\'.'patch -o " . v:fname_out . " " . v:fname_in . " < " . v:fname_diff)
endfunction

"----------------------------------------
" ノーマルモード
"----------------------------------------
"ヘルプ検索
nnoremap <F1> K
"現在開いているvimスクリプトファイルを実行
nnoremap <F8> :source %<CR>
"強制全保存終了を無効化
nnoremap ZZ <Nop>
"カーソルをj k では表示行で移動する。物理行移動は<C-n>,<C-p>
"キーボードマクロには物理行移動を推奨
"h l はノーマルモードのみ行末、行頭を超えることが可能に設定(whichwrap) 
" zvはカーソル位置の折り畳みを開くコマンド
nnoremap <Down> gj
nnoremap <Up>   gk
nnoremap h <Left>zv
"nnoremap j gj
"nnoremap k gk
nnoremap l <Right>zv

"swapファイルをまとめて置く場所(DropBox対策)
set swapfile
set directory=~/.vimswap

"backupファイルをまとめて置く場所(DropBox対策)
set backup
set backupdir=~/.vimbackup


highlight zenkakuda cterm=underline ctermfg=black guibg=black
if has('win32') && !has('gui_running')
	" win32のコンソールvimはsjisで設定ファイルを読むので、
	" sjisの全角スペースの文字コードを指定してやる
	match zenkakuda /\%u8140/
else
	match zenkakuda /　/ "←全角スペース
endif


set foldmethod=marker

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" unite.vim {{{
" 入力モードで開始する
let g:unite_enable_start_insert=1
" }}}

" NeoComplCache {{{
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1
" Use auto select
"let g:neocomplcache_enable_auto_select = 1
" Use camel case completion.
let g:neocomplcache_enable_camel_case_completion = 0
" Use underbar completion.
let g:neocomplcache_enable_underbar_completion = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
" Set manual completion length.
let g:neocomplcache_manual_completion_start_length = 2
" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
            \ 'default' : '',
            \ 'vimshell' : $HOME.'/.vimshell_hist',
            \ 'scheme' : $HOME.'/.gosh_completions', 
            \ 'scala' : $DOTVIM.'/dict/scala.dict', 
            \ 'ruby' : $DOTVIM.'/dict/ruby.dict'
            \ }

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
   let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'
"
"ilet g:neocomplcache_snippets_dir = $HOME.'/snippets'
autocmd! FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd! FileType eruby,html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd! FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd! FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd! FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
      
" Enable heavy omni completion.
    if !exists('g:neocomplcache_omni_patterns')
        let g:neocomplcache_omni_patterns = {}
    endif
    let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete   
autocmd FileType ruby :set dictionary=~/.vim/dict/ruby.dict
set complete+=k

" Customized key-mappings.
inoremap <expr><C-j>  neocomplcache#manual_filename_complete()

" <CR>: close popup and save indent.
inoremap <expr><CR> pumvisible() ? neocomplcache#smart_close_popup() : "\<CR>" 
" <TAB>: completion.
""inoremap <expr><Tab>  neocomplcache#start_manual_complete()
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
" <C-h>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()
" <Esc>,<Del>,<BS>: Cancel Popup (VSライクな動作)
inoremap <expr><Esc>  neocomplcache#cancel_popup()."\<ESC>"     
inoremap <expr><Del>  neocomplcache#cancel_popup()."\<Del>"
inoremap <expr><BS>  neocomplcache#cancel_popup()."\<BS>"
" カーソルでポップアップさせない
inoremap <expr><Up> pumvisible() ? neocomplcache#close_popup()."\<Up>" : "\<Up>"
inoremap <expr><Down> pumvisible() ? neocomplcache#close_popup()."\<Down>" : "\<Down>"

" NeoComplCache }}}

" QuickRunの設定 {{{
 let g:quickrun_config = {'runmode': 'async:vimproc'}

 if strlen($rvm_bin_path)
	let g:quickrun_config['ruby'] = {
\		'command': 'ruby',
\		'exec': '$rvm_bin_path/ruby %s',
\		'tempfile': '{tempname()}.rb'
\	}
endif
 
if has('win32') 
	let g:vimproc_dll_path = $VIMRUNTIME . '/autoload/proc.dll'
elseif has('gui_running') 
  let g:vimproc_dll_path = $VIMRUNTIME . '/autoload/proc.so'
else
  let g:neocomplcache_enable_at_startup = 0
  imap ^[OA <Up>
  imap ^[OB <Down>
  imap ^[OC <Right>
  imap ^[OD <Left>

   let g:vimproc_dll_path = $VIMRUNTIME . '/autoload/proc.so'
endif

let g:quickrun_config.markdown = {
\ 'outputter' : 'null',
\ 'command' : 'open',
\ 'cmdopt' : '-a',
\ 'args' : 'Marked',
\ 'exec' : '%c %o %a %s',
\ }

" QuickRun }}}

" rubycomplete.vim
autocmd FileType ruby,eruby set omnifunc=rubycomplete#Complete
autocmd FileType ruby,eruby let g:rubycomplete_buffer_loading = 1
autocmd FileType ruby,eruby let g:rubycomplete_rails = 1
autocmd FileType ruby,eruby let g:rubycomplete_classes_in_global = 1

"------------------------------------
" vim-rails
"------------------------------------
""{{{
"有効化
let g:rails_default_file='config/database.yml'
let g:rails_level = 4
let g:rails_mappings=1
let g:rails_modelines=0
" let g:rails_some_option = 1
" let g:rails_statusline = 1
" let g:rails_subversion=0
" let g:rails_syntax = 1
" let g:rails_url='http://localhost:3000'
" let g:rails_ctags_arguments='--languages=-javascript'
" let g:rails_ctags_arguments = ''
function! SetUpRailsSetting()
nnoremap <buffer><Space>r :R<CR>
nnoremap <buffer><Space>a :A<CR>
nnoremap <buffer><Space>m :Rmodel<Space>
nnoremap <buffer><Space>c :Rcontroller<Space>
nnoremap <buffer><Space>v :Rview<Space>
nnoremap <buffer><Space>p :Rpreview<CR>
endfunction
 
aug MyAutoCmd
au User Rails call SetUpRailsSetting()
aug END
 
aug RailsDictSetting
au!
aug END
"}}}

"<TAB>で補完
function! InsertTabWrapper()
  if pumvisible()
    return "\<c-n>"
  endif
  let col = col('.') - 1
  if !col || getline('.')[col -1] !~ '\k\|<\|/'
    return "\<tab>"
  elseif exists('&omnifunc') && &omnifunc == ''
    return "\<c-n>"
  else
    return "\<c-x>\<c-o>"
  endif
endfunction

inoremap <tab> <c-r>=InsertTabWrapper()<cr>
" Set augroup.
augroup MyAutoCmd
    autocmd!
augroup END

    autocmd MyAutoCmd BufWritePost $MYVIMRC source $MYVIMRC | 
if has('gui_running') && !(has('win32') || has('win64'))
    " .vimrcの再読込時にも色が変化するようにする
    autocmd MyAutoCmd BufWritePost $MYVIMRC nested source $MYVIMRC
else
    " .vimrcの再読込時にも色が変化するようにする
    autocmd MyAutoCmd BufWritePost $MYVIMRC source $MYVIMRC | 
                \if has('gui_running') | source $MYGVIMRC  
    autocmd MyAutoCmd BufWritePost $MYGVIMRC if has('gui_running') | source $MYGVIMRC
endif

" magic comment{{{
function! MagicComment()
    let magic_comment = "# -*- coding: utf-8 -*-\n"
    let pos = getpos(".")
    call cursor(1, 0)
    execute ":normal i" . magic_comment
    call setpos(".", pos)
endfunction

map <silent> <F12> :call MagicComment()<CR>
" magic comment }}}
" octoeditor {{{images/
let g:octopress_path = '~/satrex.github.com/octopress'
map <Leader>on  :OctopressNew<CR>
map <Leader>ol  :OctopressList<CR>
map <Leader>og  :OctopressGrep<CR>
nmap ,og  :OctopressGenerate<CR>:!open http://blog.satrex.dev<CR>
nmap ,od  :OctopressDeploy<CR>:!open http://blog.satrex.jp<CR>
let g:octopress_post_suffix = "md"
let g:octopress_post_date = "%Y-%m-%d %H:%M"
" octoeditor }}}
let g:screenshot_dir = "$HOME" . "\/Desktop"
" octopressの絡みで、zshとrvmを有効にしたい


" CoffeeScript {{{
let g:quickrun_config = {}
let g:quickrun_config['coffee'] = {'command' : 'coffee', 'exec' : ['%c -cbp %s']}
" }}}

       
nnoremap ,to :NERDTree<CR>
nnoremap <C-E> :NERDTree<CR>

"inoremap <c-r>=InsertTabWrapper()<cr>
let g:NeoComplCache_EnableAtStartUp = 1
"inoremap { {}<LEFT>
"inoremap [ []<LEFT>
"inoremap ( ()<LEFT>
"inoremap " ""<LEFT>
"inoremap ' ''<LEFT>
"vnoremap { "zdi{<C-R>z}<ESC>
"vnoremap [ "zdi[<C-R>z]<ESC>
"vnoremap ( "zdi(<C-R>z)<ESC>
"vnoremap " "zdi"<C-R>z"<ESC>
"vnoremap ') "zdi'<C-R>z'<ESC>

" オリジナル定義:Ruby用
"noremap class class<cr>end<up><right><right>
"inoremap module module<cr>end<up><right><right><right>
"inoremap while while<cr>end<up><right><right>
"inoremap {\| {\|\|<cr>}<esc><up>$i
"inoremap do\| do\|\|<cr>end<esc><up>$i
"inoremap do# do  <cr><cr>end<up>
"inoremap if# if  then<cr>end<up>
"nnoremap <s-cr> $a<cr>
"inoremap <s-cr> <esc>$<cr>i
" オリジナル定義:emacsライクな動作
inoremap <C-CR> <CR><ESC>ki
nnoremap <C-CR> ^i<CR><ESC>k
inoremap <C-n> <DOWN>
inoremap <C-p> <UP>
inoremap <C-F> <RIGHT>
inoremap <C-B> <LEFT>
inoremap <C-a> <ESC>^i
inoremap <C-e> <Esc>$a
""inoremap <DOWN> <C-N>
""imap <silent> <C-D><C-D> <C-R>=strftime("%d %m %Y")<CR>


" オリジナル定義:VSライクな動作
noremap <silent> <F5> <ESC>:<C-u>QuickRun<CR>
inoremap <silent> <F5> <ESC>:<C-u>QuickRun<CR>
nnoremap <silent> <Space>ev  :<C-u>edit $MYVIMRC<CR>
nnoremap <silent> <Space>eg  :<C-u>edit $MYGVIMRC<CR>
let g:quickrun_config.javascript = {'command': 'node'}
 
" C-kでコメントアウト
noremap <C-k> ^i/*<ESC>$a*/<ESC>
vnoremap <C-k> "zdi/*<C-R>z*/<ESC>
inoremap <C-k> <ESC>^i/*<ESC>$a*/<ESC>

" Wでウィンドウサイズが変わるのを防止 
command! W w 

" タブ切り替え
noremap <C-n> <ESC>:tabnext<CR> 
noremap <C-p> <ESC>:tabprev<CR>

" バッファ切り替え
noremap <C-b> <ESC>:bn<CR>

" ウィンドウを閉じずにバッファを閉じるKwbd
:com! Kwbd let kwbd_bn= bufnr("%")|enew|exe "bdel ".kwbd_bn|unlet kwbd_bn 

filetype off                   " (1)
set rtp+=~/.vim/bundle/vundle/  " (2)
call vundle#rc()               " (3)
filetype on

" memolist.vim
map <Leader>mn  :MemoNew<CR>
map <Leader>ml  :MemoList<CR>
map <Leader>mg  :MemoGrep<CR>
let g:memolist_path = " ~/Dropbox/Documents/memo"

" surround.vim
  let g:surround_insert_tail = "<++>"

" original repos on github
Bundle 'gmarik/vundle'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-surround'
"Bundle 'msanders/snipmate.vim'
Bundle 'unite.vim'
Bundle 'Shougo/neocomplcache.git'
Bundle 'thinca/vim-quickrun'
Bundle 'thinca/vim-ref'
Bundle 'glidenote/memolist.vim'
" Bundle 'L9'
" Bundle 'FuzzyFinder'
Bundle 'mattn/zencoding-vim'
" Bundle 'Markdown'
Bundle 'glidenote/octoeditor.vim'
nmap mf :FufFile <C-r>=expand(g:memolist_path."/")<CR><CR>
Bundle 'kchmck/vim-coffee-script.git'
Bundle 'kana/vim-textobj-user'

" Ruby用
Bundle 'tpope/vim-rvm.git'
Bundle 'rhysd/unite-ruby-require.vim'
Bundle 'rhysd/neco-ruby-keyword-args'
Bundle 'rhysd/vim-textobj-ruby'
Bundle 'Shougo/neocomplcache-rsense'
Bundle 'tpope/vim-rails'

Bundle 'git://git.wincent.com/command-t.git'
Bundle 'Shougo/vimshell'
Bundle 'Shougo/vimproc'
Bundle 'satrex/VimSketchUpRuby'
Bundle 'scrooloose/nerdtree'
Bundle 'kana/vim-smartinput'
Bundle 'ack.vim'

" non github repos


command! -nargs=0 CopyTestMethod call <SID>CopyTestMethod()
function! s:CopyTestMethod()
    execute search('\[TestMethod', 'bc')
    let defLine = line('.') 
    let defStr = getbufline('%', defLine + 1)
    let endLine = searchpair('{','','}', '')
    let testMethodBody = getbufline('%', defLine - 1, endLine - 1) 
    let endLine = defLine + len(testMethodBody) - 2
    
    let times = str2nr( input("How many times copy method?"))
    while(0 < times)

      let testMethodDef = substitute( defStr[0], "Test", printf("Test%03d", times), 'c')
"      echo testMethodDef
      let testMethodBody[2] = testMethodDef
      ""    echo "start = " . defLine "end = " . endLine
      let failed = append(endLine , testMethodBody)
      let   times = times - 1
    endwhile
endfunction

nnoremap yt :CopyTestMethod<CR>
" paste as imageRef
function! InsertImageRef()
    let image = input("Image title: ", "")
endfunction

command! -nargs=0 UtestAppend call <SID>UtestAppend()

function! s:UtestAppend()
   let target = s:GetTargetName()
  if strlen(target) <= 0
    echomsg 'Not test target file: ' . expand('%')
    return 0
  endif
endfunction " s:UtestAppend()

function! s:GetTargetName()
  if expand('%:e') ==# 'cs'
    return expand('%')
else
    return ''
  endif
endfunction " s:GetTargetName() 

"<leader>Wで現在のファイルをFirefoxで開く
noremap <Leader>W :silent !open -a firefox %<CR>
augroup MyBrowserReload
  command! -bar BrowserReload silent !osascript $HOME/bin/reload.scpt
augroup END
nnoremap <silent> <Leader>rl :BrowserReload<CR>

" VimSketchUp {{{
let g:su_plugin_path = "/Library/Application\ Support/Google\ SketchUp\ 8/SketchUp/Plugins/"
nnoremap <Leader>sun  :SketchUpRubyNew<CR>
nnoremap <Leader>sul  :SketchUpRubyList<CR>
nnoremap <Leader>sug  :SketchUpRubyGrep<CR>
nnoremap <leader>sur :SketchUpRubyRun<CR>
nnoremap <leader>sud :SketchUpRubyDeploy<CR>
" VimSketchUp }}}

" vim-ruby{{{
compiler ruby

let ruby_space_errors=1 
" vim-ruby }}}

" Kwbd{{{
 nnoremap <silent> q :Kwbd<CR>
" Kwbd}}}

" ウィンドウを閉じずにバッファを閉じる
command! Ebd call EBufdelete()
function! EBufdelete()
    let l:currentBufNum = bufnr("%")
    let l:alternateBufNum = bufnr("#")

    if buflisted(l:alternateBufNum)
        buffer #
    else
        bnext
    endif

    if buflisted(l:currentBufNum)
        execute "silent bwipeout".l:currentBufNum
        " bwipeoutに失敗した場合はウインド
        " ウ上のバッファを復元
        if bufloaded(l:currentBufNum) != 0
            execute "buffer " . l:currentBufNum
        endif
    endif
endfunction

noremap <C-c> <ESC>:Ebd<CR> 


" 日本語環境
:set encoding=utf-8
:set fileencodings=ucs-bom,iso-2022-jp-3,iso-2022-jp,eucjp-ms,euc-jisx0213,euc-jp,sjis,cp932,utf-8
:set fenc=utf-8
