" JumpToVerticalOccurrence.vim: Like f{char}, but searching the same screen column, not line.
"
" DEPENDENCIES:
"   - JumpToVerticalOccurrence.vim autoload script
"   - CountJump/Motion.vim autoload script
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.00.005	15-Jan-2014	ENH: Implement repeat of operator-pending
"				]V{char} mappings without re-querying the {char}.
"	004	14-Jan-2014	FIX: Work around missing autoload of Funcrefs in
"				Vim 7.0/1.
"	003	11-Jan-2014	Add ]! / [! variant that jumps to last
"				continuous occurrence of character under cursor.
"	002	03-Jan-2014	Change default mapping from ,j / ,k to ]V / [V.
"				Change mapping configuration from
"				<Plug>-mappings to configuration variables.
"				Add ]v / [v variant that jumps to the character
"				under the cursor. This is also useful for
"				repeating the ]V mappings without the query.
"				Add ]| / [| variant that jumps to non-whitespace
"				character in the same column.
"	001	02-Jan-2014	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_JumpToVerticalOccurrence') || (v:version < 700)
    finish
endif
let g:loaded_JumpToVerticalOccurrence = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration ---------------------------------------------------------------

if ! exists('g:JumpToVerticalOccurrence_CharUnderCursorMapping')
    let g:JumpToVerticalOccurrence_CharUnderCursorMapping = 'v'
endif
if ! exists('g:JumpToVerticalOccurrence_QueriedMapping')
    let g:JumpToVerticalOccurrence_QueriedMapping = 'V'
endif
if ! exists('g:JumpToVerticalOccurrence_NonWhitespaceMapping')
    let g:JumpToVerticalOccurrence_NonWhitespaceMapping = '<Bar>'
endif
if ! exists('g:JumpToVerticalOccurrence_LastSameCharMapping')
    let g:JumpToVerticalOccurrence_LastSameCharMapping = '!'
endif


"- mappings --------------------------------------------------------------------

if v:version < 702 | runtime autoload/JumpToVerticalOccurrence.vim | endif  " The Funcref doesn't trigger the autoload in older Vim versions.

call CountJump#Motion#MakeBracketMotionWithJumpFunctions(
\   '', g:JumpToVerticalOccurrence_CharUnderCursorMapping, '',
\   function('JumpToVerticalOccurrence#CharUnderCursorForward'),
\   function('JumpToVerticalOccurrence#CharUnderCursorBackward'),
\   '', '', 0
\)
call CountJump#Motion#MakeBracketMotionWithJumpFunctions(
\   '', g:JumpToVerticalOccurrence_QueriedMapping, '',
\   function('JumpToVerticalOccurrence#QueriedForward'),
\   function('JumpToVerticalOccurrence#QueriedBackward'),
\   '', '', 0
\)
" Additional repeat mappings to avoid the re-query on repeat of the
" operator-pending mappings.
onoremap <Plug>JumpToVerticalOccurrenceQueriedRepeatForward  :<C-u>call call(function('JumpToVerticalOccurrence#QueriedForward'), ['o', 1])<CR>
onoremap <Plug>JumpToVerticalOccurrenceQueriedRepeatBackward :<C-u>call call(function('JumpToVerticalOccurrence#QueriedBackward'), ['o', 1])<CR>

call CountJump#Motion#MakeBracketMotionWithJumpFunctions(
\   '', g:JumpToVerticalOccurrence_NonWhitespaceMapping, '',
\   function('JumpToVerticalOccurrence#NonWhitespaceForward'),
\   function('JumpToVerticalOccurrence#NonWhitespaceBackward'),
\   '', '', 0
\)
call CountJump#Motion#MakeBracketMotionWithJumpFunctions(
\   '', g:JumpToVerticalOccurrence_LastSameCharMapping, '',
\   function('JumpToVerticalOccurrence#LastSameCharForward'),
\   function('JumpToVerticalOccurrence#LastSameCharBackward'),
\   '', '', 0
\)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
