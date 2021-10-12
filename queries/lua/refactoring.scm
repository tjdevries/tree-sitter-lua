
;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
(variable_declaration
 (local)
 (variable_declarator
  (identifier) @definition.local_var))


;; grabs all the arguments that are passed into the function.  Needed for
;; function extraction, 106
(parameter_list (identifier) @definition.function_argument)

(function) @definition.scope
(function_statement) @definition.scope
