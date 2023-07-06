((function_call
    prefix: (
             (identifier) @_prefix_1
             (identifier) @_prefix_2)
    
    args: (string_argument) @c)

 (#eq? @_prefix_2 "cdef")
 (#offset! @c 0 2 0 -2))


(comment) @comment

((function_call 
    prefix: (
             (identifier) @_prefix_1
             (identifier) @_prefix_2)
    args: (string_argument) @vim)

 (#eq? @_prefix_1 "vim")
 (#eq? @_prefix_2 "cmd")
 (#offset! @vim 0 2 0 -2))

(documentation_command usage: (_) @vim)
