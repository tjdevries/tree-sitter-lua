(variable_declaration
  documentation: (emmy_documentation) @func
  name: (variable_declarator (identifier) @name)) @doc

(function_statement
  documentation: (emmy_documentation) @func
  name: (function_name (identifier) @name)) @doc

; (module_return_statement (identifier) @exported)

; Get the briefs for the module
((documentation_brief) @brief)


((documentation_tag) @tag)


((documentation_config) @config)


((documentation_class) @class)

