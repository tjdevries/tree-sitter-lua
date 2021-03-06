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
  - If you have a typo it will do `file_order` sorting
- `class_order`:
  - `file_order` (default)
  - `ascending`
  - `descending`
  - If you have a typo it will do `file_order` sorting
  <!----> TODO(conni2461): DO WE WANT THIS? IF YES IMPLEMENT IT
- `field_order`:
  - `file_order` (default)
  - `ascending`
  - `descending`
  - If you have a typo it will do `file_order` sorting

## Class

You can define your own classes and types to give a better sense of the Input of another function.
Another good usecase for this are structs defined by ffi.

Input:

```lua
---@class Array : Map @number indexed starting at 1
---@field count number: Always handy to have a count
---@field type string: Imagine having a type for an array
---@field begin function: It even has a begin()?! Is this cpp?
---@field end function: It even has an end()?! Get out of here cpp! Oh by the way did you know that fields are wrapping? I didn't and this should prove this.
```

Output:

```
Array : Map                                                            *Array*
    number indexed starting at 1

    Parents: ~
        |Map|

    Fields: ~
        {count} (number) Always handy to have a count
        {type} (string) Imagine having a type for an array
        {begin} (function) It even has a begin()?! Is this cpp?
        {end} (function) It even has an end()?! Get out of here cpp! Oh by the
                         way did you know that fields are wrapping? I didn't
                         and this should prove this.
```

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

## Return

You can specify a return parameter with `---@return type: desc`

```lua
local math = {}

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
---@return number: bigger number
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

    Return: ~
        table: bigger number
```

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
