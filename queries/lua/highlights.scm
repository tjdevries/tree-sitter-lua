;;; Highlighting for lua

;;; Builtins
;; Keywords

[
  (if_start)
  (if_then)
  (if_elseif)
  (if_else)
  (if_end)]
@conditional

[
  (for_start)
  (for_in)
  (for_do)
  (for_end)]
@repeat

[
  (while_start)
  (while_do)
  (while_end)]
@repeat

[
  (repeat_start)
  (repeat_until)
] @repeat

[
  (return_statement)
  (module_return_statement)
  (break_statement)
] @keyword


; [
;  "goto"
; ] @keyword

;; Operators

; TODO: I think I've made a bunch of these nodes.
;   we might be able to just use those!

[
 "not"
 "and"
 "or"]
@keyword.operator

[
 "="
 "~="
 "=="
 "<="
 ">="
 "<"
 ">"
 "+"
 "-"
 "%"
 "/"
 "//"
 "*"
 "^"
 "&"
 "~"
 "|"
 ">>"
 "<<"
 ".."
 "#"]
@operator



;; Punctuation
[
  ","
  "."
] @punctuation.delimiter

;; Brackets
[
 (left_paren)
 (right_paren)
 "["
 "]"
 "{"
 "}"]
@punctuation.bracket

;; Variables
(identifier) @variable
(
  (identifier) @variable.builtin
  (eq? @variable.builtin "self")
)
; (preproc_call
;   directive: (preproc_directive) @_u
;   argument: (_) @constant
;   (#eq? @_u "#undef"))

;; Constants
(boolean) @boolean
(nil) @constant.builtin
(ellipsis) @constant ;; "..."
(local) @keyword

;; Functions
(function_call_paren) @function.bracket

[
  (function_start)
  (function_end)]
@keyword.function

(emmy_type (identifier) @type)
(emmy_parameter
 (identifier) @parameter
 description: (_)? @comment) @comment

(emmy_note) @comment
(emmy_see) @comment

; TODO: Make the container so we can still highlight the beginning of the line
; (emmy_eval_container) @comment
; (_emmy_eval_container) @comment

(emmy_return) @comment

; TODO: returns

(emmy_header) @comment
(emmy_ignore) @comment
(documentation_brief) @comment

(function_call
  [
    ((identifier)+ @identifier . (identifier) @function.call . (function_call_paren))
    ((identifier) @function.call . (function_call_paren))])

(function_call
  prefix: (identifier) @function.call
  args: (string_argument) @string)

(function_call
 prefix: (identifier) @function.call
 args: (table_argument) )

; (function [(function_name) (identifier)] @function)
; (function ["function" "end"] @keyword.function)
; (local_function [(function_name) (identifier)] @function)
; (local_function ["function" "end"] @keyword.function)
; (function_definition ["function" "end"] @keyword.function)

; TODO: Do I have replacements for these.
; (property_identifier) @property
; (method) @method

; (function_call (identifier) @function . (arguments))
; (function_call (field (property_identifier) @function) . (arguments))

;; Parameters
; (parameters (identifier) @parameter)

;; Nodes
; (table ["{" "}"] @constructor)
(comment) @comment
(string) @string
(number) @number
; (label_statement) @label

; INJECTION HIGHLIGHTING
(
 (function_call
  prefix: (identifier) @_cdef_identifier
  args: (string_argument) @IncludedC)

 (#eq? @_cdef_identifier "cdef"))

;; Error
(ERROR) @error
