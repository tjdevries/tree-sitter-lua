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

  STATEMENT: 15,
  PROGRAM: 16,
};

module.exports = grammar({
  name: 'lua',

  extras: $ => [
    /[\s\n]/,
    $.comment,
  ],

  inline: $ => [
    $._expression,
    $._field_expression,
    $.field_separator,
    $.prefix_exp,

    $.function_body,
    //
    // TODO: Decide if we want to show these or not.
    //$.variable_declarator
  ],

  conflicts: $ => [
    // [$._expression, $.variable_declarator],
    // [$._expression, $.function_call_statement],
    // [$.function_name, $.function_name_field],
    // [$._var, $.function_arguments],
  ],

  rules: {

    program: $ => prec(
      PREC.PROGRAM,
      seq(
        any_amount_of($._statement),
        optional(alias($.return_statement, $.module_return_statement))
      ),
    ),

    _statement: $ => prec(
      PREC.STATEMENT,
      seq(
        choice(
          $.variable_declaration,
          $.function_call,
          $.do_statement,
          $.while_statement,
          $.repeat_statement,
          $.if_statement,
          $.for_statement,
          $.function_statement,
        ),
        optional(';')
      ),
    ),

    _last_statement: $ => choice(
      $.return_statement,
      "break"
    ),

    _chunk: $ => choice(
      seq(
        one_or_more($._statement),
        optional($._last_statement),
      ),
      $._last_statement,
    ),

    _block: $ => $._chunk,

    _expression: $ => seq(
      choice(
        $.nil,
        $.boolean,
        $.number,
        $.string,
        $.ellipsis,
        $.function,
        $.prefix_exp,
        $.tableconstructor,
        $.binary_operation,
        $.unary_operation,
      ),
    ),

    // Primitives {{{
    nil: _ => "nil",

    boolean: _ => choice("true", "false"),

    number: _ => /[0-9]+/,

    _inner_string: _ => /[a-zA-Z0-9_ ]+/,

    string: $ => choice(
      seq(
        '"', $._inner_string, '"',
      ),
      seq(
        "'", $._inner_string, "'",
      )
    ),

    ellipsis: _ => "...",

    function_name: $ => seq(
      list_of($.identifier, alias(".", $.table_dot), false),
      optional(seq(alias(":", $.table_colon), $.identifier))
    ),

    function: $ => seq(
      "function",
      $.function_body
    ),

    function_body: $ => seq(
      alias($.left_paren, $.function_body_paren),
      optional($.parameter_list),
      alias($.right_paren, $.function_body_paren),
      field("body", optional($._block)),
      alias("end", $.function_body_end),
    ),

    parameter_list: $ => choice(
      seq(
        $.identifier_list,
        optional(seq(
          ",",
          $.ellipsis
        ))
      ),
      $.ellipsis
    ),

    // }}}

    _expression_list: $ => list_of($._expression, ","),

    binary_operation: $ =>
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

    unary_operation: $ => 
      prec.left(PREC.UNARY, seq(choice('not', '#', '-', '~'), $._expression)),

    local: _ => "local",

    base_variable_declaration: $ => seq(
      // TODO: Is this the best way of marking something local
      optional($.local),
      $.variable_declarator,
      any_amount_of(",", $.variable_declarator),
      "=",
      $._expression,
      any_amount_of(",", $._expression),
    ),

    variable_declaration: $ => seq(
      // TODO: Is this the best way of marking something local
      optional($.local),
      $.variable_declarator,
      any_amount_of(",", $.variable_declarator),
      "=",
      $._expression,
      any_amount_of(",", $._expression),
    ),

    variable_declarator: $ => $._var,

    // var ::=  identifier | prefixexp `[´ exp `]´ | prefixexp `.´ identifier 
    _var: $ => prec(
      PREC.PRIORITY,
      choice(
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
    ),

    var_list: $ => list_of($._var, ",", false),

    identifier_list: $ => prec.right(
        PREC.COMMA,
        list_of($.identifier, ",", false),
    ),

    return_statement: $ => prec(PREC.PRIORITY, seq(
      "return",
      $._expression
    ),),

    // Blocks {{{
    do_statement: $ => seq(
      alias("do", $.do_start),
      $._block,
      alias("end", $.do_end),
    ),

    while_statement: $ => seq(
      alias("while", $.while_start),
      $._expression,
      alias("do", $.while_do),
      $._block,
      alias("end", $.while_end),
    ),

    repeat_statement: $ => seq(
      alias("repeat", $.repeat_start),
      $._block,
      alias("until", $.repeat_until),
      $._expression,
    ),

    if_statement: $ => seq(
      alias("if", $.if_start),
      $._expression,
      alias("then", $.if_then),
      $._block,
      any_amount_of(seq(
        alias("elseif", $.if_elseif),
        $._expression,
        alias("then", $.if_then),
        $._block
      )),
      optional(seq(
        alias("else", $.if_else),
        $._block,
      )),
      alias("end", $.if_end),
    ),

    for_statement: $ => seq(
      alias("for", $.for_start),
      choice(
        $.for_numeric,
        $.for_generic,
      ),
      alias("do", $.for_do),
      $._block,
      alias("end", $.for_end),
    ),

    for_numeric: $ => seq(
      field("var", $.identifier),
      "=",
      field("start", $._expression),
      ",",
      field("finish", $._expression),
      optional(seq(
        ",",
        field("step", $._expression)
      )),
    ),

    for_generic: $ => seq(
      field("identifier_list", $.identifier_list),
      // alias("in", $.for_in),
      "in",
      field("expression_list", $._expression_list),
    ),

    function_statement: $ => seq(
      optional($.emmy_documentation),
      choice(
        seq(
          alias("local", $.local),
          "function",
          field("name", $.identifier),
        ),
        seq(
          "function",
          field("name", $.function_name),
        ),
      ),
      $.function_body
    ),

    // }}}

    // Table {{{
    tableconstructor: $ => seq(
      "{",
      optional($.fieldlist),
      "}",
    ),

    fieldlist: $ => prec(PREC.COMMA, list_of($.field, $.field_separator, true),),

    field: $ => $._field_expression,

    // `[´ exp `]´ `=´ exp | identifier `=´ exp | exp
    _named_field_expression: $ => prec(
      PREC.PRIORITY,
      seq(
        field("name", $.identifier),
        "=",
        field("value", $._expression),
      )
    ),

    _expression_field_expression: $ => prec(
      PREC.PRIORITY,
      seq(
        // TODO: Decide if we really want to keep these...
        //          It will be useful when we want to highlight them
        //          in a particular color for people :)
        field("field_left_bracket", alias($.left_bracket, $.field_left_bracket)),
        field("key", $._expression),
        field("field_right_bracket", alias($.right_bracket, $.field_right_bracket)),
        "=",
        field("value", $._expression),
      )
    ),

    _field_expression: $ => choice(
      $._expression_field_expression,
      $._named_field_expression,
      field("value", $._expression),
    ),

    field_separator: _ => choice(",", ";"),
    // }}}

    // Function {{{
    _prefix_exp: $ => choice(
      $._var,
      $.function_call,
      seq(
        '(',
        $._expression,
        ')',
      )
    ),

    prefix_exp: $ => $._prefix_exp,

    function_call: $ => prec.left(
      PREC.FUNCTION,
      seq(
        field("prefix", $.prefix_exp),
        choice(
          $._args,
          $._self_call,
        )
      ),
    ),

    _args: $ => choice(
      $._parentheses_call,
      $._table_call,
      $._string_call,
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

    _self_call: $ => seq(
      alias(":", $.self_call_colon),
      $.identifier,
      $._args
    ),

    function_arguments: $ => seq(
      $._expression,
      optional(repeat(seq(
        ",",
        $._expression
      )))
    ),

    // }}}

    identifier: _ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    // Dummy Fields {{{
    left_paren: _ => "(",
    right_paren: _ => ")",

    left_bracket: _ => "[",
    right_bracket: _ => "]",
    // }}}

    // Documentation {{
    emmy_comment: _ => /---[^@].*\n/,

    emmy_type: $ => $.identifier,

    // Definition:
    // ---@param param_name MY_TYPE[|other_type] [@comment]
    //
    // I don't think this is needed (read this as: I hate it)
    // ---@param example table @this is my comment hello
    //
    // ---@param example table hello
    // ---@param example (table): hello
    emmy_parameter: $ =>
      seq(
        /---@param\s*/,
        field('name', $.identifier),
        field('type', list_of($.emmy_type, "|")),

        // TODO: We should not require this `:` here. It should be optional.
        /\s*:\s*/,

        field('description', $.parameter_description),
        /\n/,
      ),

    parameter_description: _ => /[^\n]*/,

    return_description: $ => seq(
      /---@return/,
      field('type', list_of($.emmy_type, "|")),
      /\n/,
    ),

    emmy_documentation: $ =>
      prec.left(
        PREC.STATEMENT,
        repeat1(
          choice(
            $.emmy_comment,
            $.emmy_parameter,
            $.return_description,
          ),
        ),
      ),
    // }}}
    // Comments {{{
    comment: _ => token(
      choice(
        seq('--', /[^-].*\r?\n/),
        // comment_level_regex(0),
        // comment_level_regex(1),
        // comment_level_regex(2),
        // comment_level_regex(3),
        // comment_level_regex(4),
      ),
    ),
    // }}}
  },
});

function any_amount_of() {
  return repeat(seq(...arguments));
}

function one_or_more() {
  return repeat1(seq(...arguments));
}

function list_of(match, sep, trailing) {
  return trailing ?
    seq(match, any_amount_of(sep, match))
    : seq(match, any_amount_of(sep, match), optional(sep));
}

function comment_level_regex(level) {
  // prettier-ignore
  return new RegExp(
    // Starts a comment
    '--' + '\\s*'

    // Opening brackets
    + ''.concat('\\[', '='.repeat(level), '\\[')

    // Match "Non-Endy" type stuff.
    + '([^\\]][^=]|\\r?\\n)*' 

    // Start on ending
    + '\\]+' + ''.concat('='.repeat(level), '\\]'),

    'g',
  );
}
