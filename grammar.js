// TODO: Decide how to expose all the random characters that are used,
//          and how to easily highlight them if you want.
//

const PREC = {
  COMMA: -1,
  FUNCTION: 1,
  PRIORITY: 2,

  OR: 3,      // => or
  AND: 4,     // => and
  COMPARE: 5, // => < <= == ~= >= >
  BIT_OR: 6,  // => |
  BIT_NOT: 7, // => ~
  BIT_AND: 8, // => &
  SHIFT: 9,   // => << >>
  CONCAT: 10, // => ..
  PLUS: 11,   // => + -
  MULTI: 12,  // => * /             // %
  UNARY: 13,  // => not # - ~
  POWER: 14,  // => ^
};

module.exports = grammar({
  name: 'lua',

  extras: _ => [/[\s\n]/],
  inline: $ => [
    $._expression,
    $._field_expression,
    $.fieldsep,
    $.prefix_exp,
  ],

  conflicts: $ => [
    [$._var, $.function_arguments],
  ],

  rules: {

    program: $ => choice(
      seq($._expression),
      alias($.return_statement, $.module_return_statement)
    ),

    _expression: $ => choice(
      $.variable_declaration,

      $.function_call,
      $.tableconstructor,
      $.number,
      $.string,
      $.identifier,
      $.operation,
    ),

    _expression_list: $ => seq(
      $._expression,
      optional(repeat(seq(
        ",",
        $._expression
      )))
    ),

    operation: $ =>
      choice(...[
        ['or', PREC.OR],
        ['and', PREC.AND],
        ['<', PREC.COMPARE],
        ['<=', PREC.COMPARE],
        ['==', PREC.COMPARE],
        ['~=', PREC.COMPARE],
        ['>=', PREC.COMPARE],
        ['>', PREC.COMPARE],
        ['|', PREC.BIT_OR],
        ['~', PREC.BIT_NOT],
        ['&', PREC.BIT_AND],
        ['<<', PREC.SHIFT],
        ['>>', PREC.SHIFT],
        ['+', PREC.PLUS],
        ['-', PREC.PLUS],
        ['*', PREC.MULTI],
        ['/', PREC.MULTI],
        ['//', PREC.MULTI],
        ['%', PREC.MULTI],
      ].map(([operator, precedence]) =>
        prec.left(precedence, seq($._expression, operator, $._expression)),
      ),
      ...[
        ['..', PREC.CONCAT],
        ['^', PREC.POWER],
      ].map(([operator, precedence]) =>
        prec.right(precedence, seq($._expression, operator, $._expression)),
      ),
    ),

    local: _ => "local",

    base_variable_declaration: $ => seq(
      // TODO: Is this the best way of marking something local
      optional($.local),
      $.variable_declarator,
      optional_repeated_seq(",", $.variable_declarator),
      "=",
      $._expression,
      optional_repeated_seq(",", $._expression),
    ),

    variable_declaration: $ => prec(
      PREC.PRIORITY,
      seq(
        // TODO: Is this the best way of marking something local
        optional($.local),
        $.variable_declarator,
        optional_repeated_seq(",", $.variable_declarator),
        "=",
        $._expression,
        optional_repeated_seq(",", $._expression),
      )
    ),

    variable_declarator: $ => $._var,

    // var ::=  Name | prefixexp `[´ exp `]´ | prefixexp `.´ Name 
    _var: $ => choice(
      $.identifier,
      seq(
        $.prefix_exp,
        '[',
        $._expression,
        ']',
      ),
      seq(
        $.prefix_exp,
        '.',
        $.identifier,
      ),
    ),

    return_statement: $ => seq(
      "return",
      $._expression
    ),

    // Table {{{
    tableconstructor: $ => seq(
      "{",
      optional($.fieldlist),
      "}",
    ),

    fieldlist: $ => seq(
      $.field,
      optional(repeat(seq(
        $.fieldsep,
        $.field
      ))),
      optional($.fieldsep)
    ),

    field: $ => prec(
      PREC.COMMA,
      $._field_expression
    ),

    // `[´ exp `]´ `=´ exp | Name `=´ exp | exp
    _named_field_expression: $ => prec(
      PREC.PRIORITY,
      seq(
        field("name", $.identifier),
        "=",
        field("value", $._expression),
      )
    ),

    field_left_bracket: _ => "[",
    field_right_bracket: _ => "]",

    _expression_field_expression: $ => prec(
      PREC.PRIORITY,
      seq(
        // TODO: Decide if we really want to keep these...
        //          It will be useful when we want to highlight them
        //          in a particular color for people :)
        field("field_left_bracket", $.field_left_bracket),
        field("key", $._expression),
        field("field_right_bracket", $.field_right_bracket),
        "=",
        field("value", $._expression),
      )
    ),

    _field_expression: $ => choice(
      $._expression_field_expression,
      $._named_field_expression,
      field("value", $._expression),
    ),

    fieldsep: _ => choice(",", ";"),
    // }}}

    // Function {{{
    prefix_exp: $ => choice(
      $._var,
      $.function_call,
      seq(
        '(',
        $._expression,
        ')',
      )
    ),

    prefix: $ => $.prefix_exp,

    function_call: $ => seq(
      field("prefix", $.prefix),
      choice(
        $._parentheses_call,
        $._string_call,
        $._table_call,
      )
    ),

    _parentheses_call: $ => seq(
      alias($.left_paren, $.function_call_paren),
      field(
        "args",
        optional($.function_arguments)
      ),
      alias($.right_paren, $.function_call_paren),
    ),

    _string_call: $ => field(
      "args",
      // TODO: Decide if this is really the name we want to use.
      alias($.string, $.string_argument),
    ),

    _table_call: $ => field(
      "args",
      alias($.tableconstructor, $.table_argument)
    ),

    function_arguments: $ => seq(
      $._expression,
      optional(repeat(seq(
        ",",
        $._expression
      )))
    ),

    // }}}

    number: _ => /[0-9]+/,

    string: _ => seq(
      '"',
      /[a-zA-Z0-9_ ]+/,
      '"',
    ),

    identifier: _ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    // Dummy Fields {{{
    left_paren: _ => "(",
    right_paren: _ => ")",

    right_bracket: _ => "[",
    left_bracket: _ => "]",
    // }}}
  },
});

function optional_repeated_seq() {
  return optional(repeat(seq(...arguments)));
}

