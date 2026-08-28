;; Cedar policy highlights, replacing the query bundled with cedar.nvim.
;;
;; The bundled query captures whole parent nodes -- (policy), (scope) and
;; (condition) are each @keyword -- so every token inside a policy inherits a
;; keyword tint and the narrower captures only layer on top. It also has no rule
;; for comments, strings, numbers or booleans at all. This one captures tokens.
;;
;; There is deliberately no `;; extends` modeline: this replaces the bundled
;; query rather than adding to it. Note that placing the file here is NOT what
;; makes that happen -- vim.treesitter.query.get_files keeps the FIRST
;; non-extends file it finds on runtimepath and silently discards the rest, and
;; cedar.nvim's copy is always found first. init_base.lua therefore loads this
;; file explicitly via vim.treesitter.query.set. The conventional path is kept
;; anyway, so that dropping the override is all it takes to go back to plain
;; runtimepath resolution if the bundled query ever improves.
;;
;; Node names here come from the parser itself, not the grammar source --
;; `vim.treesitter.language.inspect('cedar')` lists them, and it is worth
;; re-checking against that after a :TSUpdate. A typo'd node name is a hard
;; query error that disables cedar highlighting outright.

;; -------------------------------------------------------------- comments ---

(comment) @comment @spell

;; -------------------------------------------------------------- keywords ---

(permit) @keyword
(forbid) @keyword

[
  (when)
  (unless)
] @keyword.conditional

[
  "if"
  "then"
  "else"
] @keyword.conditional

;; ------------------------------------------------------------- variables ---

[
  (principal)
  (action)
  (resource)
  (context)
] @variable.builtin

;; The scope spells the request variables as bare tokens rather than as the
;; named nodes above, so both spellings need capturing.
[
  "principal"
  "action"
  "resource"
] @variable.builtin

[
  (all_principals)
  (all_actions)
  (all_resources)
] @variable.builtin

;; Slots, which appear only in policy templates.
[
  "?principal"
  "?resource"
] @variable.parameter.builtin

;; -------------------------------------------------------------- literals ---

(str) @string
(int) @number

[
  (true)
  (false)
] @boolean

;; An entity is `Path::"id"`. Capturing the path and the id separately beats
;; painting the whole entity one colour, which is what the bundled query did.
(path) @type

;; ------------------------------------------------------------- operators ---

[
  "=="
  "!="
  "<"
  "<="
  ">"
  ">="
  "&&"
  "||"
  "!"
  "+"
  "-"
  "*"
] @operator

[
  "in"
  "is"
  "has"
  "like"
] @keyword.operator

;; ------------------------------------------------------------- functions ---

;; `contains` and `containsAll` are keywords in this grammar, not calls.
;; Note it has no `containsAny` token, so that method parses as a plain call.
[
  "contains"
  "containsAll"
] @function.method

;; An extension call wraps its name in a (path); this pattern must stay below
;; `(path) @type` above, which also matches it, so that the later capture wins.
(ext_fun_call (path (identifier) @function.call))
(call_expression
  function: (selector_expression field: (field_identifier) @function.method.call))

;; ------------------------------------------------------------ properties ---

(selector_expression field: (field_identifier) @property)
(record_attribute key: (identifier) @property)

;; ----------------------------------------------------------- annotations ---

(annotation (identifier) @attribute)
(annotation "@" @punctuation.special)

;; ----------------------------------------------------------- punctuation ---

[ "(" ")" "{" "}" "[" "]" ] @punctuation.bracket
[ "," ";" "." "::" ":" ] @punctuation.delimiter
