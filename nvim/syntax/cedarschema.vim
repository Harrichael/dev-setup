" Vim syntax file
" Language: Cedar schema, Cedar-format -- .cedarschema
"
" A hand-written syntax file rather than a tree-sitter grammar because no
" grammar for the Cedar schema language exists: chrnorm/tree-sitter-cedar, the
" one cedar.nvim installs, covers the policy language only. The schema format is
" a small declarative language, so regex highlighting loses very little here.
"
" Grammar reference:
"   https://docs.cedarpolicy.com/schema/human-readable-schema-grammar.html

if exists("b:current_syntax")
  finish
endif

syn case match

syn keyword cedarschemaTodo contained TODO FIXME XXX NOTE
syn match cedarschemaComment "//.*$" contains=cedarschemaTodo,@Spell

syn keyword cedarschemaKeyword namespace entity action type enum tags in
syn keyword cedarschemaAppliesTo appliesTo principal resource context

" Long, String and Bool are the primitives; the lowercase four are extension
" types, which really are spelled in lowercase in the Cedar schema format.
syn keyword cedarschemaType Long String Bool Set
syn keyword cedarschemaType ipaddr decimal datetime duration

" `__cedar` is reserved, and is how a schema disambiguates a builtin type from a
" same-named one of its own.
syn keyword cedarschemaReserved __cedar

syn match cedarschemaAnnotation "@\h\w*"

" Any path segment that a `::` follows names a namespace or an entity type.
syn match cedarschemaEntityType "\<\h\w*\ze\s*::"

" Declaration heads. `entity` and `action` may declare a comma-separated list in
" one statement, hence the repeat; `namespace` and `type` take a single name, but
" a namespace name is a path.
"
" Everything that needs to skip a leading keyword uses lookbehind rather than
" the more obvious `\zs`. `\zs` is silently inert in a syntax pattern -- the item
" simply never matches -- so these rules looked correct and highlighted nothing.
syn match cedarschemaDeclName "\%(\<\%(entity\|action\)\s\+\)\@<=\h\w*\%(\s*,\s*\h\w*\)*"
syn match cedarschemaDeclName "\%(\<\%(namespace\|type\)\s\+\)\@<=\h\w*\%(\s*::\s*\h\w*\)*"

" A membership constraint is the other place a bare type appears, as `in Group`.
syn match cedarschemaEntityType "\%(\<in\s\+\)\@<=\h\w*\%(\s*::\s*\h\w*\)*"

" A type in value position may be a user-defined entity or common type, which no
" keyword list can enumerate, so anything there that is not a builtin gets the
" same colour. Builtins still win: they are syn-keywords, which outrank a match.
syn match cedarschemaEntityType "\%(\%([:=]\|\<tags\)\s*\)\@<=\h\w*\%(\s*::\s*\h\w*\)*"

" Every bracketed list in this grammar holds entity types -- `in [..]` and
" `appliesTo`'s `principal:`/`resource:` -- with one exception, `enum ["a","b"]`,
" whose string members keep their own highlighting inside the region.
syn region cedarschemaEntityList matchgroup=cedarschemaDelimiter start="\[" end="\]"
      \ contains=cedarschemaPathName,cedarschemaString,cedarschemaComment
syn match cedarschemaPathName contained "\<\h\w*\%(\s*::\s*\h\w*\)*"

" Marks an optional attribute, as in `department?: String`.
syn match cedarschemaOptional "?\ze\s*:"

syn match cedarschemaEscape contained +\\\%([\\"nrt0]\|x\x\x\|u{\x\{1,6}}\)+
syn region cedarschemaString start=+"+ skip=+\\.+ end=+"+ contains=cedarschemaEscape,@Spell

hi def link cedarschemaTodo       Todo
hi def link cedarschemaComment    Comment
hi def link cedarschemaKeyword    Keyword
hi def link cedarschemaAppliesTo  Identifier
hi def link cedarschemaType       Type
hi def link cedarschemaReserved   Special
hi def link cedarschemaAnnotation PreProc
hi def link cedarschemaDeclName   Function
hi def link cedarschemaEntityType Type
hi def link cedarschemaPathName   Type
hi def link cedarschemaDelimiter  Delimiter
hi def link cedarschemaOptional   Special
hi def link cedarschemaString     String
hi def link cedarschemaEscape     SpecialChar

let b:current_syntax = "cedarschema"
