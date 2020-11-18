(
 [
  (variable_declaration
    documentation: (emmy_documentation) @func
    name: (variable_declarator (identifier) @name)) @doc

  (function_statement
    documentation: (emmy_documentation) @func
    name: (function_name (identifier) @name)) @doc
  ]

 (module_return_statement (identifier) @exported)
 (#eq? @exported @name))
