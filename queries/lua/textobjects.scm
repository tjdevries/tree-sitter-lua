(function) @function.outer
(function_statement) @function.outer

; TODO: Need to make this work, might want to change grammar
;       to have entire body be one node, rather than fields.
(function_body) @function.inner

(for_statement) @loop.outer
(while_statement) @loop.outer
(repeat_statement) @loop.outer

; TODO: @conditional.inner
(if_statement) @conditional.outer

(function_call (function_arguments) @call.inner)
(function_call) @call.outer

(function_arguments (_) @parameter.inner)
(parameter_list (_) @parameter.inner)

(comment) @comment.outer

(field) @element

;; TODO: It would be cool to figure out how to make variables good
; (variable_declaration) @variable

; ((function
;   . (function_name) . (parameters) . (_) @_start
;   (_) @_end .)
;  (#make-range! "function.inner" @_start @_end))
; ((local_function
;   . (identifier) . (parameters) . (_) @_start
;   (_) @_end .)
;  (#make-range! "function.inner" @_start @_end))
; ((function_definition
;   . (parameters) . (_) @_start
;   (_) @_end .)
;  (#make-range! "function.inner" @_start @_end))
; 
; ((function
;   . (function_name) . (parameters) . (_) @function.inner .))
; ((local_function
;   . (identifier) . (parameters) . (_) @function.inner .))
; ((function_definition
;   . (parameters) . (_) @function.inner .))
