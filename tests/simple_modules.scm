;;; Return Number
; return 1
(program
 (return_statement (number)))

;;; Return String
; return "hello"
(program
 (return_statement (string)))

;;; Return variable
; return foobar
(program
 (return_statement (identifier)))
