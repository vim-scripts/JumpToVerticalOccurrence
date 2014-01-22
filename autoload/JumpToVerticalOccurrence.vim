" JumpToVerticalOccurrence.vim: Like f{char}, but searching the same screen column, not line.
"
" DEPENDENCIES:
"   - ingo/motion/omap.vim autoload script
"   - ingo/query/get.vim autoload script
"   - ingo/text.vim autoload script
"   - CountJump.vim autoload script
"   - repeat.vim (vimscript #2136) autoload script (optional)
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.004	15-Jan-2014	ENH: Implement repeat of operator-pending
"				]V{char} mapping without re-querying the {char}.
"				Since Vim 7.3.918, Vim will re-invoke the motion
"				function, but that will still re-query. We need
"				to use repeat.vim and pass it a special repeat
"				mapping that re-uses the stored {char}. Special
"				handling of the "c"hange operator is taken from
"				https://github.com/tek/vim-argh/blob/master/autoload/argh.vim#L54.
"				In s:Jump, store the last queried char in s:char
"				and re-use that on new "repeat" target.
"				Add repeat.vim calls in
"				JumpToVerticalOccurrence#Queried...() in case of
"				omaps.
"	003	11-Jan-2014	Implement jump to last continuous occurrence of
"				character under cursor variant.
"	002	03-Jan-2014	Implement jump to character under cursor
"				variant.
"				Implement jump to non-whitespace character in
"				the same column.
"	001	02-Jan-2014	file creation

function! s:LastSameJump( virtCol, pattern, count, directionFlag, mode )
    if a:count
	" Search for a different non-whitespace character in the exact column.
	let l:beyondColumnCharPattern = printf('\C\V\%%%dv%s\@!\S', a:virtCol, a:pattern)
    else
	" Search for one of:
	" - a different character in the exact column
	" - a whitespace character just before the column, with no match at it
	" - a shorter line
	let l:beyondColumnCharPattern = printf('\C\V\%%%dv%s\@!\|\%%<%dv\s\%%>%dv\|\%%<%dv\$',
	\   a:virtCol, a:pattern, a:virtCol, a:virtCol, a:virtCol
	\)
    endif

    let l:beyondLnum = search(l:beyondColumnCharPattern, a:directionFlag . 'nw')
    if l:beyondLnum
	if empty(a:directionFlag)
	    let l:lastSameLnum = l:beyondLnum - 1
	    if l:lastSameLnum <= line('.')
		" Search has wrapped around.
		if line('.') < line('$')
		    " Where there are still following lines, move to the last
		    " one.
		    let l:lastSameLnum = line('$')
		elseif l:beyondLnum > 1
		    " When at the last line and there are same columns at the
		    " beginning, wrap around to the last same column at the
		    " beginning of the buffer.
		else
		    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
		    return
		endif
	    endif
	else    " backward
	    let l:lastSameLnum = l:beyondLnum + 1
	    if l:lastSameLnum >= line('.')
		" Search has wrapped around.
		if line('.') > 1
		    " Where there are still previous lines, move to the first
		    " one.
		    let l:lastSameLnum = 1
		elseif l:beyondLnum < line('$')
		    " When at the first line and there are same columns at the
		    " end, wrap around to the first same column at the end of
		    " the buffer.
		else
		    execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
		    return
		endif
	    endif
	endif

	if a:mode ==? 'v'
	    normal! gv
	endif

	normal! m'
	call ingo#cursor#Set(l:lastSameLnum, a:virtCol)
    else
	execute "normal! \<C-\>\<C-n>\<Esc>" | " Beep.
    endif
endfunction
function! s:Jump( target, mode, directionFlag )
    let l:count = v:count   " Save the given [count] before the normal mode command clobbers it.

    if a:target ==# 'query'
	let s:char = ingo#query#get#Char()
	if empty(s:char) | return [0, 0] | endif
	let l:char = s:char
    elseif a:target ==# 'repeat'
	let l:char = s:char
    endif

    if a:mode ==? 'v'
	" In visual mode, the invocation of the CountJump plugin has positioned
	" the cursor to the start of the selection. We need to re-establish the
	" selection to get the actual original cursor position when the mapping
	" was triggered.
	normal! gv
    endif

	let l:virtCol = virtcol('.')
	if a:target ==# 'cursor' || a:target ==# 'lastsame'
	    let l:char = ingo#text#GetChar(getpos('.')[1:2])
	endif

    if a:mode ==? 'v'
	execute 'normal! ' (l:count ? l:count : '') . "\<Esc>"
	" The given [count] is restored by prepending it to the harmless <Esc>
	" command.
    endif

    if a:target ==# 'nonwhitespace'
	let l:pattern = '\S'
    else
	let l:pattern = escape(l:char, '\')
    endif
    if empty(l:pattern) | return [0, 0] | endif

    if a:target ==# 'lastsame'
	return s:LastSameJump(l:virtCol, l:pattern, l:count, a:directionFlag, a:mode)
    else
	let l:columnCharPattern = printf('\C\V\%%%dv%s', l:virtCol, l:pattern)
	return CountJump#CountJump(a:mode, l:columnCharPattern, a:directionFlag . 'W')
    endif
endfunction

function! JumpToVerticalOccurrence#QueriedForward( mode, ... )
    let l:operator = v:operator
    let l:count = v:count1
    call s:Jump((a:0 ? 'repeat' : 'query'), a:mode, '')
    if a:mode ==# 'o'
	call ingo#motion#omap#repeat("\<Plug>JumpToVerticalOccurrenceQueriedRepeatForward", l:operator, l:count)
    endif
endfunction
function! JumpToVerticalOccurrence#QueriedBackward( mode, ... )
    let l:operator = v:operator
    let l:count = v:count1
    call s:Jump((a:0 ? 'repeat' : 'query'), a:mode, 'b')
    if a:mode ==# 'o'
	call ingo#motion#omap#repeat("\<Plug>JumpToVerticalOccurrenceQueriedRepeatBackward", l:operator, l:count)
    endif
endfunction

function! JumpToVerticalOccurrence#CharUnderCursorForward( mode )
    return s:Jump('cursor', a:mode, '')
endfunction
function! JumpToVerticalOccurrence#CharUnderCursorBackward( mode )
    return s:Jump('cursor', a:mode, 'b')
endfunction

function! JumpToVerticalOccurrence#NonWhitespaceForward( mode )
    return s:Jump('nonwhitespace', a:mode, '')
endfunction
function! JumpToVerticalOccurrence#NonWhitespaceBackward( mode )
    return s:Jump('nonwhitespace', a:mode, 'b')
endfunction

function! JumpToVerticalOccurrence#LastSameCharForward( mode )
    return s:Jump('lastsame', a:mode, '')
endfunction
function! JumpToVerticalOccurrence#LastSameCharBackward( mode )
    return s:Jump('lastsame', a:mode, 'b')
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
