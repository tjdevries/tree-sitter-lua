;;; Return Number
; return 1
(program
 (module_return_statement (number)))

;;; Return String
; return "hello"
(program
 (module_return_statement (string)))

;;; Return variable
; return foobar
(program
 (module_return_statement (identifier)))
