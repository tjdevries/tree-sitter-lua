;; Variable and field declarations
((variable_declarator
   (identifier) @definition.var))

;; Parameters
(parameter_list (identifier) @definition.parameter)


;; Scopes
[
  (program)
  (function_statement)
  (function_start)
  (if_statement)
  (for_statement)
  (repeat_statement)
  (while_statement)
  (do_statement)] @scope

;; References
[(identifier)] @reference
