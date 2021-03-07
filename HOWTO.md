# How to write emmy documentation

## Brief

Brief is used to describe a module. This is an example input:

```lua
---@brief [[
--- This will document a module and will be found at the top of each file. It uses an internal markdown renderer
--- so you don't need to worry about formatting. It will wrap the lines into one paragraph and
--- will make sure that the max line width is < 80.
---
--- To start a new paragraph with a newline.
---
--- To explicitly do a breakline do a `<br>` at the end.<br>
--- This is useful sometimes
---
--- We also support itemize and enumerate
--- - Item 1
---   - Item 1.1 This item will be wrapped as well and the result will be as expected. This is really handy.
---     - Item 1.1.1
---   - Item 1.2
--- - Item 2
---
--- 1. Item
---   1.1. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna
---   aliquyam erat, sed diam voluptua.
---     1.1.1. Item
---   1.2. Item
--- 2. Item
---
--- <pre>
--- You can disable formatting with a
--- pre block.
--- This is useful if you want to draw a table or write some code
--- </pre>
---
---@brief ]]
```

Example output:

```
This will document a module and will be found at the top of each file. It uses
an internal markdown renderer so you don't need to worry about formatting. It
will wrap the lines into one paragraph and will make sure that the max line
width is < 80.

To start a new paragraph with a newline.

To explicitly do a breakline do a `<br>` at the end.
This is useful sometimes

We also support itemize and enumerate
- Item 1
  - Item 1.1 This item will be wrapped as well and the result will be as
    expected. This is really handy.
    - Item 1.1.1
  - Item 1.2
- Item 2

1. Item
  1.1. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy
       eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam
       voluptua.
    1.1.1. Item
  1.2. Item
2. Item

You can disable formatting with a
pre block.
This is useful if you want to draw a table or write some code
```

## tag

Add a tag to your module. This is suggested:

```lua
---@tag your_module
```

This will result into this module header:
```
================================================================================
                                                                   *your_module*
```

## Config

You can configure docgen on file basis. For example you can define how `functions` or `classes`
are sorted.

```lua
---@config { ['function_order'] = 'ascending', ['class_order'] = 'descending' }
```

Available keys value pairs are:
- `function_order`:
  - `file_order` (default)
  - `ascending`
  - `descending`
  - or it can accept a function. example: `function(tbl) table.sort(tbl, function(a, b) return a > b end) end`
  - If you have a typo it will do `file_order` sorting
- `class_order`:
  - `file_order` (default)
  - `ascending`
  - `descending`
  - or it can accept a function. example: `function(tbl) table.sort(tbl, function(a, b) return a > b end) end`
  - If you have a typo it will do `file_order` sorting
- `field_order`:
  - `file_order` (default)
  - `ascending`
  - `descending`
  - or it can accept a function. example: `function(tbl) table.sort(tbl, function(a, b) return a > b end) end`
  - If you have a typo it will do `file_order` sorting

## Function header

You can describe your functions.
Note: We will only generate documentation for functions that are exported with the module.

```lua
local m = {}

--- We will not generate documentation for this function
local some_func = function()
  return 5
end

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
m.__hidden = function()
  return 5
end

--- The documentation for this function will be generated.
--- The markdown renderer will be used again.<br>
--- With the same set of features
m.actual_func = function()
  return 5
end

return m
```

Output:

```
m.actual_func()                                              *m.actual_func()*
    The documentation for this function will be generated. The markdown
    renderer will be used again.
    With the same set of features.
```

## Parameter

You can specify parameters and document them with `---@param name type: desc`

```lua
local math = {}

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
math.max = function(a, b)
  if a > b then
    return a
  end
  return b
end

return math
```

Output:

```
math.max({a}, {b})                                     *math.load_extension()*
    Will return the bigger number


    Parameters: ~
        {a} (number)  first number
        {b} (number)  second number
```

## Field

Can be used to describe a parameter table.

```lua
local x = {}

--- This function has documentation
---@param t table: some input table
---@field k1 number: first key of input table
---@field key function: second key of input table
---@field key3 table: third key of input table
function x.hello(t)
  return 0
end

return x
```

Output:

```
x.hello({t})                                                       *x.hello()*
    This function has documentation


    Parameters: ~
        {t} (table)  some input table

    Fields: ~
        {k1}   (number)    first key of input table
        {key}  (function)  second key of input table
        {key3} (table)     third key of input table
```

## Return

You can specify a return parameter with `---@return type: desc`

```lua
local math = {}

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
---@return number: bigger number
function math.max = function(a, b)
  if a > b then
    return a
  end
  return b
end

return math
```

Output:

```
math.max({a}, {b})                                     *math.load_extension()*
    Will return the bigger number


    Parameters: ~
        {a} (number)  first number
        {b} (number)  second number

    Return: ~
        table: bigger number
```

## See

Reference something else.

```lua
local math = {}

--- Will return the smaller number
---@param a number: first number
---@param b number: second number
---@return number: smaller number
---@see math.max
function math.min(a, b)
  if a < b then
    return a
  end
  return b
end

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
---@return number: bigger number
---@see math.min
function math.max(a, b)
  if a > b then
    return a
  end
  return b
end

return math
```

Output:

```
math.min({a}, {b})                                               *math.min()*
    Will return the smaller number


    Parameters: ~
        {a} (number)  first number
        {b} (number)  second number

    Return: ~
        number: smaller number

    See: ~
        |x.max()|

math.max({a}, {b})                                               *math.max()*
    Will return the bigger number


    Parameters: ~
        {a} (number)  first number
        {b} (number)  second number

    Return: ~
        number: bigger number

    See: ~
        |x.min()|
```

## Class

You can define your own classes and types to give a better sense of the Input or Ouput of a function.
Another good usecase for this are structs defined by ffi.

This is a more complete (not functional) example where we define the documentation of the c struct
`passwd` and return this struct with a function

Input:

```lua
local m = {}

---@class passwd @The passwd c struct
---@field pw_name string: username
---@field pw_name string: user password
---@field pw_uid number: user id
---@field pw_gid number: groupd id
---@field pw_gecos string: user information
---@field pw_dir string: user home directory
---@field pw_shell string: user default shell

--- Get user by id
---@param id number: user id
---@return passwd: returns a password table
function m.get_user(id)
  return ffi.C.getpwuid(id)
end

return m
```

Output:

```
passwd                                                                *passwd*
    The passwd c struct

    Fields: ~
        {pw_name}  (string)  user password
        {pw_uid}   (number)  user id
        {pw_gid}   (number)  groupd id
        {pw_gecos} (string)  user information
        {pw_dir}   (string)  user home directory
        {pw_shell} (string)  user default shell


m.get_user({id})                                                *m.get_user()*
    Get user by id


    Parameters: ~
        {id} (number)  user id

    Return: ~
        passwd: returns a password table
```

## Function class

WIP

## Eval

You can evaluate arbitrary code. For example if you have a static table you can
do generate a table that will be part of the `description` output.

```lua
local m = {}

--- The documentation for this function will be generated.
--- The markdown renderer will be used again.<br>
--- With the same set of features
---@eval { ['description'] = require('your_module').__format_keys() }
m.actual_func = function()
  return 5
end

local static_values = {
  'a',
  'b',
  'c',
  'd',
}

m.__format_keys()
  -- we want to do formatting
  local table = { '<pre>', 'Static Values: ~' }

  for _, v in ipairs(static_values) do
    table.insert(table, '    ' .. v)
  end

  table.insert(table, '</pre>')
  return table
end

return m
```

Output:

```
m.actual_func()                                              *m.actual_func()*
    The documentation for this function will be generated. The markdown
    renderer will be used again.
    With the same set of features.

    Static Values: ~
        a
        b
        c
        d
```
