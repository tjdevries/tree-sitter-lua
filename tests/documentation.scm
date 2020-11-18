;;; Comments before function
; --  This is a comment
; function not_documented()
; end
(program
  (comment)
  (function_statement
    (function_start)
    (function_name (identifier))
    (function_body_paren)
    (function_body_paren)
    (function_end)))

;;; Simple documentation
; --- hello world
; function cool_function()
;   return true
; end
(program
  (function_statement
    documentation: (emmy_documentation (emmy_comment))

    (function_start)
    name: (function_name (identifier))
    (function_body_paren)
    (function_body_paren)
    body: (return_statement (boolean))
    (function_end)))

;;; Two lines of top level documentation
; --- hello world
; --- goodbye world
; function cool_function()
;   return true
; end
(program
  (function_statement
    documentation: (emmy_documentation (emmy_comment) (emmy_comment))

    (function_start)
    name: (function_name (identifier))
    (function_body_paren)
    (function_body_paren)
    body: (return_statement (boolean))
    (function_end)))

;;; Full documentation
; --- A function description
; ---@param p string: param value
; ---@param x table: another value
; ---@return true
; function cool_function(p, x)
;   return true
; end
(program
  (function_statement
    documentation: (emmy_documentation
                     (emmy_comment)

                     (emmy_parameter
                       name: (identifier)
                       type: (emmy_type (identifier))
                       description: (parameter_description))

                     (emmy_parameter
                       name: (identifier)
                       type: (emmy_type (identifier))
                       description: (parameter_description))

                     (emmy_return
                       type: (emmy_type (identifier))))

    (function_start)
    name: (function_name (identifier))

    (function_body_paren)
    (parameter_list (identifier) (identifier))
    (function_body_paren)

    body: (return_statement (boolean))
    (function_end)))


;;; Multiple types with spaces
; --- A function description
; ---@param p string| number : param value
; function cool_function(p) end
(program
  (function_statement
    documentation: (emmy_documentation
                     (emmy_comment)

                     (emmy_parameter
                       name: (identifier)
                       type: (emmy_type (identifier))
                       type: (emmy_type (identifier))
                       description: (parameter_description)))

    (function_start)
    name: (function_name (identifier))

    (function_body_paren)
    (parameter_list (identifier))
    (function_body_paren)
    (function_end)))


;;; Should work for variables as well
; --- Example of my_func
; ---@param y string: Y description
; M.my_func = function(y)
; end
(program
  (variable_declaration
    documentation: (emmy_documentation
                     (emmy_comment)
                     (emmy_parameter
                       name: (identifier)
                       type: (emmy_type (identifier))
                       description: (parameter_description)))

    name: (variable_declarator (identifier) (identifier))
    value: (function 
             (function_start)
             (function_body_paren)
             (parameter_list (identifier))
             (function_body_paren)
             (function_end))))

;;; Real life example from neovim
; --- Store Diagnostic[] by line
; ---@param diagnostics Diagnostic[]: hello
; ---@return table<number, Diagnostic[]>
; local _diagnostic_lines = function(diagnostics)
; end
(program
  (variable_declaration
    documentation: (emmy_documentation
                     (emmy_comment)
                     (emmy_parameter
                       name: (identifier)
                       type: (emmy_type (emmy_type_list type: (emmy_type (identifier))))
                       description: (parameter_description))
                     (emmy_return
                       type: (emmy_type (emmy_type_map
                                          key: (emmy_type (identifier))
                                          value: (emmy_type (emmy_type_list type: (emmy_type (identifier))))))))

    (local)
    name: (variable_declarator (identifier))
    value: (function 
             (function_start)
             (function_body_paren)
             (parameter_list (identifier))
             (function_body_paren)
             (function_end))))


;;; Real life example from neovim 2
; --- Save diagnostics to the current buffer.
; ---
; --- Handles saving diagnostics from multiple clients in the same buffer.
; ---@param diagnostics Diagnostic[]
; ---@param bufnr number
; ---@param client_id number
; function M.save(diagnostics, bufnr, client_id)
;   validate {
;     diagnostics = {diagnostics, 't'},
;     bufnr = {bufnr, 'n'},
;     client_id = {client_id, 'n', true},
;   }
; end
(program
  (function_statement
    (emmy_documentation
      (emmy_comment)
      (emmy_comment)
      (emmy_parameter
        (identifier)
        (emmy_type
          (emmy_type_list
            (emmy_type
              (identifier)))))
      (emmy_parameter
        (identifier)
        (emmy_type
          (identifier)))
      (emmy_parameter
        (identifier)
        (emmy_type
          (identifier))))
    (function_start)
    (function_name
      (identifier)
      (table_dot)
      (identifier))
    (function_body_paren)
    (parameter_list
      (identifier) (identifier) (identifier))
    (function_body_paren)
    (function_call
      (identifier)
      (table_argument
        (fieldlist
          (field
            (identifier)
            (tableconstructor
              (fieldlist
                (field (identifier))
                (field (string)))))
          (field
            (identifier)
            (tableconstructor
              (fieldlist
                (field (identifier))
                (field (string)))))
          (field
            (identifier)
            (tableconstructor
              (fieldlist
                (field (identifier))
                (field (string))
                (field (boolean))))))))
    (function_end)))

;;; Multiline params
; --- Get the diagnostics by line
; ---@param opts table|nil: Configuration keys
; ---             - severity: (DiagnosticSeverity, default nil)
; function M.get_line_diagnostics(bufnr, line_nr, opts, client_id)
; end
()
