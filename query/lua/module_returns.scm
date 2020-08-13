(
 (program
  (variable_declaration
   (variable_declarator (identifier) @variable))

  (module_return_statement
   (tableconstructor
    (fieldlist
    (field 
     (identifier) @exported
     (identifier) @defined)))))

 (#eq? @defined @variable)
)
