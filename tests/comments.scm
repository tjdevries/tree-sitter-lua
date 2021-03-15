;;; Can do simple comments
; -- hello world
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

;;; Can do comments with strings inside
; -- local description = table.concat(
; --   map(function(val)
; --     if val == '' then return '\n' end
; --     return val
; --   end, function_metadata.description or {}),
; --   ' '
; -- )
; -- print(vim.inspect(function_metadata.description))
(program (comment) (comment) (comment) (comment) (comment) (comment) (comment) (comment))
