;;; Declare global function
; function x() return 5 end
(program
 (function_statement
  (function_start)
  name: (function_name (identifier))
  (function_body_paren)
  (function_body_paren)
  (function_body (return_statement (number)))
  (function_end)))

;;; Declare table function
; function t.x() return 5 end
(program
 (function_statement
  (function_start)
  name: (function_name (identifier) (table_dot) (identifier))
  (function_body_paren)
  (function_body_paren)
  (function_body (return_statement (number)))
  (function_end)))

;;; Declare table function
; function t:x() return 5 end
(program
 (function_statement
  (function_start)
  name: (function_name (identifier) (table_colon) (identifier))
  (function_body_paren)
  (function_body_paren)
  (function_body (return_statement (number)))
  (function_end)))

;;; Declare local function
; local function f() print("hi"); return 5 end
(program
 (function_statement
  (local)
  (function_start)
  name: (identifier)
  (function_body_paren)
  (function_body_paren)
  (function_body
    (function_call
      prefix: (identifier)
      (function_call_paren)
      args: (function_arguments (string))
      (function_call_paren))

    (return_statement (number)))
  (function_end)))

;;; Declare local function, error
; local function t.x() return 5 end
(program
 (function_statement
  (local)
  (function_start)
  (identifier)
  (ERROR (UNEXPECTED 'x'))
  (function_body_paren)
  (function_body_paren)
  (function_body (return_statement (number)))
  (function_end)))

;;; Declare function with an argument
; function f(x) end
(program
 (function_statement
  (function_start)
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (identifier))
  (function_body_paren)
  (function_end)))

;;; No trailing commas in function declaration
; function f(x,) end
(program
 (function_statement
  (function_start)
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (identifier))
  (ERROR)
  (function_body_paren)
  (function_end)))

;;; Declare function with two arguments
; function f(wow, two_vars) end
(program
 (function_statement
  (function_start)
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (identifier) (identifier))
  (function_body_paren)
  (function_end)))

;;; Declare function with ellipsis
; function f(...) end
(program
 (function_statement
  (function_start)
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (ellipsis))
  (function_body_paren)
  (function_end)))

;;; Declare function with args and ellipsis
; function f(x, ...) end
(program
 (function_statement
  (function_start)
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (identifier) (ellipsis))
  (function_body_paren)
  (function_end)))

;;; Declare a function with documentation ahead of it
; ---
; function f() end
(program
  (function_statement
    (emmy_documentation
      (emmy_header))
    (function_start)
    (function_name
      (identifier))
    (function_body_paren)
    (function_body_paren)
    (function_end)))
