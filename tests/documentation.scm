;;; Comments before function
; --  This is a comment
; function not_documented()
; end
(program
  (comment)
  (function_statement
   (function_name (identifier))
   (function_body_paren)
   (function_body_paren)
   (function_body_end)))

;;; Simple documentation
; --- hello world
; function cool_function()
;   return true
; end
(program
  (function_statement
    (emmy_documentation (emmy_comment))

    name: (function_name (identifier))
    (function_body_paren)
    (function_body_paren)
    body: (return_statement (boolean))
    (function_body_end)))

;;; Two lines of top level documentation
; --- hello world
; --- goodbye world
; function cool_function()
;   return true
; end
(program
  (function_statement
    (emmy_documentation (emmy_comment) (emmy_comment))

    name: (function_name (identifier))
    (function_body_paren)
    (function_body_paren)
    body: (return_statement (boolean))
    (function_body_end)))

;;; Full documentation
; --- A function description
; ---@param p string: param value
; ---@param x table: another value
; ---@returns true
; function cool_function(p, x)
;   return true
; end
(program
  (function_statement
    (emmy_documentation
      (emmy_comment)

      (emmy_parameter
        name: (identifier)
        type: (emmy_type (identifier))
        description: (parameter_description))

      (emmy_parameter
        name: (identifier)
        type: (emmy_type (identifier))
        description: (parameter_description))

      (return_description))

    name: (function_name (identifier))

    (function_body_paren)
    (parameter_list (identifier_list
      (identifier)
      (identifier)))
    (function_body_paren)

    body: (return_statement (boolean))
    (function_body_end)))


;;; Full documentation
; --- A function description
; ---@param p string|number: param value
; function cool_function(p) end
(program
  (function_statement
    (emmy_documentation
      (emmy_comment)

      (emmy_parameter
        name: (identifier)
        type: (emmy_type (identifier))
        type: (emmy_type (identifier))
        description: (parameter_description)))

    name: (function_name (identifier))

    (function_body_paren)
    (parameter_list (identifier_list (identifier)))
    (function_body_paren)
    (function_body_end)))

