(
 (function_call 
    prefix: (
        (identifier) @_prefix_1
        (identifier) @_prefix_2
    )
    args: (string_argument) @c)

 (#eq? @_prefix_2 "cdef")
)

(
 (function_call
  prefix: (identifier) @_prefix_1
  args: (string_argument) @lua)

 (#eq? @_prefix_1 "exec_lua"))
