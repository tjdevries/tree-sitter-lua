(function_statement
 (emmy_documentation
  (emmy_parameter
   name: (identifier) @parameter_name
   type: (emmy_type) @parameter_type
   description: (parameter_description) @parameter_description)

  (emmy_return)? @returns
  )


 name: (function_name (identifier) @var))

(variable_declaration
 (emmy_documentation
  (emmy_parameter
   name: (identifier) @parameter_name
   type: (emmy_type) @parameter_type
   description: (parameter_description) @parameter_description)

  (emmy_return)? @returns
  )

 (variable_declarator) @var)
