" File:         scrollfix.vim
" Author:       Yakov Lerner <iler.ml@gmail.com>
" Last changed: 2006-09-10
"
" This plugin, scrollfix, maintains the cursor at a fixed visual line of the
" window (except when near the beginning of file and near end of file). The
" latter is configurable. You can choose whether to fix the cursor near the
" end of file or not, see g:scrollfix_fixeof below). This is an enhancement to
" the 'set scrolloff=999' setting that allows the visual line of window to be
" anywhere, not just the middle line of window.
"
" You choose the visual line of the screen in percentages from top of screen.
" For example, setting 100 means lock cursor to the bottom line of the screen,
" setting 0 means keeping the cursor at top line of screen, setting 50 means
" middle line of screen, setting 60 (default) is about two-thirds from the top
" of the screen. As shipped, cursor is at 60% (let g:scrollfix=60). You control
" percentage of scrollfix in following ways:
" - :set g:scrollfix=NNN   " in vimrc. -1 disables plugin
" - edit file ~/.vim/plugin/scrollfix.vim, change number in line
"         :let g:scrollfix=NNN
" - command :FIX NNN
"
" CONTROL VARIABLES:
" g:scrollfix - percentage from top of screen where to lock cursor
"               -1 - disables. Default: 60
" g:scrollfix_fixeof    - 1=>fix cursor also near end-of-file; 0=>no. Default:0
" g:scrollinfo - 1=>inform when scrollfix is turned on, 0=>no. Default: 1
"
" NB:
" - You need vim version at least 7.0.91 or later (vim6 won't work).
"   If you have vim7 before 7.0.91, you can use script#1473 to build
"   & install the latest vim7 executable.
" - this is beta version of the scrollfix plugin.
"   Your feedback is welcome. Please send your feedback to iler at gmail dot com.

if exists("g:loaded_scrollfix") | finish | endif
let g:loaded_scrollfix = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" configuration 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" The vertical percentage of the screen height to keep the cursor at.
"   0 - top of the screen
"  50 - middle of the screen
" 100 - bottom of the screen
"  -1 - disables scrollfix
if !exists("g:scrollfix")
  let g:scrollfix = 50 
endif

" Fix the cursor when near the end of the file?
" 0 - no
" 1 - yes
if !exists("g:scrollfix_fixeof")
  let g:scrollfix_fixeof = 0
endif

" Display info when scrollfix runs (mainly for debugging)?
" 0 - no
" 1 - yes
if !exists("g:scrollfix_showinfo")
  let g:scrollfix_showinfo = 0
endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" version check
" if vim6, disable silently.
if v:version < 700 | finish | endif
" if version > 700, it will work.
" if version == 700, we need the specific patch, explain and disable.
if v:version == 700 && !has('patch91')
  echohl ToDo
  echo "Warning: scrollfix plugin needs newer vim version (>=7.0.91)"
  echohl
  finish
endif

if &scrolloff != 0
  echohl ToDo
  echo "Warning: scrollfix cannot be used when 'scrolloff' is not set to 0"
  echohl
  finish
endif

command!          FIXOFF    :let g:scrollfix=-1
command! -nargs=1 FIX       :let g:scrollfix=<args>
command! -nargs=1 SCROLLFIX :let g:scrollfix=<args>

augroup scrollfix
  au!
  au CursorMoved * :call <SID>ScrollFix()
augroup END

function! <SID>ScrollFix()
  " scrollfix is disabled
  if g:scrollfix < 0 | return | endif

  " do not bother to center 'special' windows
  if getcmdwintype() != '' | return | endif
  if !&modifiable && &ft != "help" | return | endif

  " scrollfix has been disabled for this buffer since it found a line that is
  " too long. keeping it enabled causes performance problems
  if exists("b:scrollfix_disabled") | return | endif
  if col('$') >= 256
    let b:scrollfix_disabled=1
    return
  endif

  let num_win_lines = winheight(0)
  let num_win_columns = winwidth(0)
  let num_buf_lines = line("$")
  let fixline = (num_win_lines * g:scrollfix) / 100
  let window = winsaveview()
  let lnum = window["lnum"]
  let topline = window["topline"]
  
  " an optimization to not center if we are moving horizontally
  if exists("b:scrollfix_last_line_num") && b:scrollfix_last_line_num == lnum
    return
  endif
  
  " cursors is at the top of the file, do not center
  if topline <= fixline && lnum <= fixline | return | endif
  
  "" if eof line is visible and visual-line is >= fixline, don't fix cursor
  if g:scrollfix_fixeof
    if (num_buf_lines < (topline + num_win_lines))
      return
    endif
  endif

  let num_lines_above = fixline
  let x = lnum
  while num_lines_above >= 0
    let x -= 1
    let fold_start = foldclosed(x)
    if fold_start > -1
      let x = fold_start
      let num_lines_above -= 1
    elseif &wrap
      let num_wrapped_lines = ((virtcol([x, '$']) - 1) / num_win_columns) + 1
      let num_lines_above -= num_wrapped_lines
    else
      let num_lines_above -= 1
    endif
  endwhile
  let x += 1
  if x != topline
    let window['topline'] = x
    call winrestview(window)
    let b:scrollfix_last_line_num = lnum
  endif

  if g:scrollfix_showinfo
    echo "scroll fixed at line " . fixline . " of " . num_win_lines." (". g:scrollfix "%)"
  endif
endfunction

" TODO:
" allow per-buffer setting, b:scrollfix
" handle window-resize event
