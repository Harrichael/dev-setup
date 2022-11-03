
function s:jumpToLast(last_string)
  :$
  execute ':?' . a:last_string
endfunction

function s:lineFindAndReplace(find, replace)
  :call feedkeys('V')
'):call feedkeys(':s/' . a:find . '/' . a:replace . '/e
endfunction

function s:fileFindAndReplace(find, replace)
'):call feedkeys(':%s/' . a:find . '/' . a:replace . '/e
endfunction

" Why can't we use let l:save = winsaveview() and call winrestview(l:save)
" instead
function s:jumpToLine(line_num)
'):call feedkeys(':' . a:line_num . '
endfunction

function s:writeToNextLine(text)
  :call feedkeys('o' . a:text . ')
endfunction

function s:copyLine()
  :call feedkeys('yy')
endfunction

function s:switchPanes()
  :call feedkeys('w')
endfunction

function CPPAddIncludeFromArg(filepath)
  let l:first_line_num = line('.')

  :call s:jumpToLast('#include "')

  " Normalize filepath variable
  let l:filepath = a:filepath
  let l:filepath = substitute(l:filepath, '#include', '', '')
  let l:filepath = substitute(l:filepath, '"', '', 'g')
  let l:filepath = trim(l:filepath)

  " Add unfiltered include
  :call s:writeToNextLine('#include "' . l:filepath . '"')
  :call feedkeys('0')
  :call feedkeys('i )
'):call feedkeys('V:s/" #include/"\r#include/e

  " Apply common copy-paste required filters
  :call s:lineFindAndReplace('"google3\/', '"')
  :call s:lineFindAndReplace('proto"', 'proto.h"')
  :call s:lineFindAndReplace('cc"', 'h"')

  :call s:jumpToLine(l:first_line_num)
endfunction

function CPPAddIncludeToOtherPane()
  :call s:copyLine()
  let l:filepath = getreg('0')
  :call s:switchPanes()
  CPPAddIncludeFromArg(l:filepath)
  :call s:switchPanes()
endfunction

function CPPAddUsingFromArg(symbol)
  let l:first_line_num = line('.')

  :call s:jumpToLast('using ::')

  let l:qualified_symbol = trim(substitute(a:symbol, 'using ::', '', ''))
  let l:qualified_symbol = substitute(l:qualified_symbol, ';', '', '')
  :call s:writeToNextLine('using ::' . l:qualified_symbol . ';')

  :call s:jumpToLine(l:first_line_num)
endfunction

function CPPAddUsingFromArgInHeader(qualified_symbol)
  let l:first_line_num = line('.')

  let l:unqualified_symbol = split(trim(a:qualified_symbol), '::')[-1]

  :call s:fileFindAndReplace(l:unqualified_symbol, a:qualified_symbol)

  :call s:jumpToLine(l:first_line_num)
endfunction
