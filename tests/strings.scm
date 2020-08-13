;;; Basic string
; local x = "hello world"
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))

;;; Basic string
; local x = 'hello world'
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))

;;; Contained string
; local x = "foo 'bar baz"
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))

;;; Bracket string
; local x = [[ my string ]]
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))

;;; Bracket string, single escape
; local x = [[ my ] string ]]
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))

;;; Bracket string 1 
; local x = [=[ my ] string ]=]
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))

;;; Bracket string 2
; local x = [==[ my ]=] string ]==]
(program
 (variable_declaration
  (local)
  (variable_declarator (identifier))
  (string)))
