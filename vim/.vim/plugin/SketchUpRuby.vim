" sketchup.vim
" Maintainer: satrex <satrex@livedoor.com>
" Version:  0.0.1
" See doc/sketchup.txt for instructions and usage.

" Code {{{1
" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set

if (exists("g:loaded_vsu") && g:loaded_vsu) || &cp
  finish
endif
let g:loaded_vsu = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists('g:su_plugin_path')
  let g:su_plugin_path = '/Library/Application\ Support/Google\ SketchUp\ 8/SketchUp/Plugins/'
endif

if !exists('g:su_labo_path')
  let g:su_labo_path = g:su_plugin_path . "laboratory/"
endif

if !exists('g:su_deploy_path')
  let g:su_deploy_path = g:su_plugin_path . "deploy/"
endif

command! -nargs=0 SketchUpRubyList :call SketchUpRuby#list()
command! -nargs=? SketchUpRubyGrep :call SketchUpRuby#grep(<q-args>)
command! -nargs=? SketchUpRubyNew :call SketchUpRuby#new(<q-args>)
command! -nargs=0 SketchUpRubyRun :call SketchUpRuby#run()
command! -nargs=? SketchUpRubyDeploy :call SketchUpRuby#deploy(<q-args>)

let &cpo = s:cpo_save

" vim:set ft=vim ts=2 sw=2 sts=2:
