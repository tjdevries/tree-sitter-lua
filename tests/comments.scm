;;; Can do simple comments
; -- hello world
(program (comment))

;;; Can do simple separator
; --
(program (comment))

;;; Can do EOL comments
; local x = 1 -- hello world
(program
 (variable_declaration (local) (variable_declarator (identifier)) (number))
 (comment))

;;; Can do simple comments
; --[[
; hello world
; more
; --]]
(program (comment))

;;; Can do weirder comments
; --[==[
; hello world
; more
; --]==]
(program (comment))
