;;; Can do a large lua file
; local m = {}
;
; --- Test Header 1
; function m.a01()
;   return 0
; end
;
; return m
(program
 (variable_declaration (local) (variable_declarator (identifier)) (tableconstructor))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (module_return_statement (identifier)))

;;; Can do a large lua file
; local m = {}
; 
; --- Test Header 1
; function m.a01()
;   return 0
; end
; 
; --- Test Header 2
; function m.a02()
;   return 0
; end
; 
; --- Test Header 3
; function m.a03()
;   return 0
; end
; 
; --- Test Header 4
; function m.a04()
;   return 0
; end
; 
; --- Test Header 5
; function m.a05()
;   return 0
; end
; 
; --- Test Header 6
; function m.a06()
;   return 0
; end
; 
; --- Test Header 7
; function m.a07()
;   return 0
; end
; 
; --- Test Header 8
; function m.a08()
;   return 0
; end
; 
; --- Test Header 9
; function m.a09()
;   return 0
; end
; 
; --- Test Header 10
; function m.a10()
;   return 0
; end
; 
; --- Test Header 11
; function m.a11()
;   return 0
; end
; 
; --- Test Header 12
; function m.a12()
;   return 0
; end
; 
; --- Test Header 13
; function m.a13()
;   return 0
; end
; 
; --- Test Header 14
; function m.a14()
;   return 0
; end
; 
; --- Test Header 15
; function m.a15()
;   return 0
; end
; 
; --- Test Header 16
; function m.a16()
;   return 0
; end

; --- Test Header 17
; function m.a17()
;   return 0
; end
; 
; return m
(program
 (variable_declaration (local) (variable_declarator (identifier)) (tableconstructor))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (function_statement (emmy_documentation (emmy_header))
  (function_start) (function_name (identifier) (table_dot) (identifier)) (function_body_paren) (function_body_paren) (return_statement (number)) (function_end))
 (module_return_statement (identifier)))
