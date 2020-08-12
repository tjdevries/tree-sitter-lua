;;; Local documentation
; --- A function description
; --@param p: param value
; --@param x: another value
; --@returns true
; local function cool_function(p, x)
;   return true
; end
(program
  (local_function
    (emmy_documentation
      (parameter_documentation
        name: (identifier)
        description: (parameter_description))
      (parameter_documentation
        name: (identifier)
        description: (parameter_description))

      (return_description))

    (identifier)
    (parameters
      (identifier)
      (identifier))

    (return_statement (true))))
;;; Full documentation with assignment
; local x = {}
; 
; --- hello world
; --@param y: add 1
; x.my_func = function(y)
;   return y + 1
; end
(program
  (local_variable_declaration
    variable: (variable_declarator (identifier)) (table))

  (variable_declaration
    documentation: (emmy_documentation
      (parameter_documentation
        name: (identifier)
        description: (parameter_description)))

    variable: (variable_declarator
      (field_expression (identifier) (property_identifier)))

    expression: (function_definition
      (parameters (identifier))
      (return_statement (binary_operation (identifier) (number))))

    ))

;;; Full documentation with assignment bracket
; local x = {}
; 
; --- hello world
; --@param y: add 1
; x["my_func"] = function(y)
;   return y + 1
; end
(program
  (variable_declaration
    (local)
    variable: (variable_declarator (identifier)) (table))

  (variable_declaration
    documentation: (emmy_documentation
      (parameter_documentation
        name: (identifier)
        description: (parameter_description)))

    variable: (variable_declarator (identifier) (string))

    expression: (function_definition
        (parameters (identifier))
        (return_statement (binary_operation (identifier) (number))))
    ))
