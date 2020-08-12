;;; Declare global function
; function x() return 5 end
(program
 (function_statement
  name: (function_name (identifier))
  (function_body_paren)
  (function_body_paren)
  body: (return_statement (number))
  (function_body_end)))

;;; Declare table function
; function t.x() return 5 end
(program
 (function_statement
  name: (function_name (identifier) (table_dot) (identifier))
  (function_body_paren)
  (function_body_paren)
  body: (return_statement (number))
  (function_body_end)))

;;; Declare table function
; function t:x() return 5 end
(program
 (function_statement
  name: (function_name (identifier) (table_colon) (identifier))
  (function_body_paren)
  (function_body_paren)
  body: (return_statement (number))
  (function_body_end)))

;;; Declare local function
; local function f() print("hi"); return 5 end
(program
 (function_statement
  (local)
  name: (identifier)
  (function_body_paren)
  (function_body_paren)
  body: (function_call
    prefix: (identifier)
    (function_call_paren)
    args: (function_arguments (string))
    (function_call_paren))
  body: (return_statement (number))
  (function_body_end)))

;;; Declare local function, error
; local function t.x() return 5 end
(program (function_statement (local) (identifier) (ERROR (UNEXPECTED 'x')) (function_body_paren) (function_body_paren) (return_statement (number)) (function_body_end)))

;;; Declare function with an argument
; function f(x) end
(program
 (function_statement
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (identifier_list (identifier)))
  (function_body_paren)
  (function_body_end)))

;;; Declare function with two arguments
; function f(wow, two_vars) end
(program
 (function_statement
  (function_name (identifier))
  (function_body_paren)
  (parameter_list (identifier_list (identifier) (identifier)))
  (function_body_paren)
  (function_body_end)))
