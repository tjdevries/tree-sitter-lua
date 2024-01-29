;;; Highlighting for lua

;;; Builtins
;; Keywords

[(if_start)
 (if_then)
 (if_elseif)
 (if_else)
 (if_end)] @keyword.conditional

[(for_start)
 (for_in)
 (for_do)
 (for_end)] @keyword.repeat

[(while_start)
 (while_do)
 (while_end)] @keyword.repeat

[(repeat_start)
 (repeat_until)] @keyword.repeat

(break_statement) @keyword.repeat

[(return_statement)
 (module_return_statement)] @keyword.return

[(do_start)
 (do_end)] @keyword

; [
;  "goto"
; ] @keyword

;; Operators

; TODO: I think I've made a bunch of these nodes.
;   we might be able to just use those!

[
 "not"
 "and"
 "or"] @keyword.operator

["="
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
 "#"] @operator



;; Punctuation
["," "."] @punctuation.delimiter

;; Brackets
[(left_paren)
 (right_paren)
 "["
 "]"
 "{"
 "}"] @punctuation.bracket

;; Variables
(identifier) @variable
(
  (identifier) @variable.builtin
  (#match? @variable.builtin "self"))

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
  (function_end)] @keyword.function

(emmy_type) @type
(emmy_literal) @string
(emmy_parameter
 (identifier) @parameter
 description: (_)? @comment) @comment

(emmy_class) @comment
(emmy_field name: (_) @property) @comment
(emmy_function_parameter
  name: (_) @parameter) 

(emmy_type_dictionary_value key: (identifier) @property)

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

(documentation_command) @comment

(function_call
  [
    ((identifier)+ @identifier . (identifier) @function.call . (function_call_paren))
    ((identifier) @function.call.lua . (function_call_paren))])

(function_call
  prefix: (identifier) @function.call.lua
  args: (string_argument) @string)

(function_call
 prefix: (identifier) @function.call.lua
 args: (table_argument))

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

;; Error
(ERROR) @error
