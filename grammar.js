// TODO: Decide how to expose all the random characters that are used,
//          and how to easily highlight them if you want.
//

const PREC = {
    COMMA: -1,
    FUNCTION: 1,
    DEFAULT: 1,
    PRIORITY: 2,

    OR: 3, // => or
    AND: 4, // => and
    COMPARE: 5, // => < <= == ~= >= >
    BIT_OR: 6, // => |
    BIT_NOT: 7, // => ~
    BIT_AND: 8, // => &
    SHIFT: 9, // => << >>
    CONCAT: 10, // => ..
    PLUS: 11, // => + -
    MULTI: 12, // => * /             // %
    UNARY: 13, // => not # - ~
    POWER: 14, // => ^

    STATEMENT: 15,
    PROGRAM: 16,
};

EQUALS_LEVELS = 5;

module.exports = grammar({
    name: "lua",

    externals: ($) => [$._multi_comment, $.string],

    extras: ($) => [/[\s\n]/, /\s/, $.comment],

    inline: ($) => [
        $._expression,
        $._field_expression,
        $.field_separator,
        $.prefix_exp,

        $.function_body,
        $._multi_comment,
    ],

    conflicts: ($) => [
        [$.variable_declarator, $._prefix_exp],
        [$.emmy_ignore, $.emmy_comment],
    ],

    rules: {
        program: ($) =>
            prec(
                PREC.PROGRAM,
                seq(
                    any_amount_of(
                        choice(
                            $._statement,
                            $._documentation_brief_container,
                            $._documentation_tag_container
                        )
                    ),
                    optional(
                        alias($.return_statement, $.module_return_statement)
                    ),
                    optional("\0")
                )
            ),

        _statement: ($) =>
            prec.right(
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
                        $.function_statement
                        // $.comment
                    ),
                    optional(";")
                )
            ),

        _last_statement: ($) => choice($.return_statement, $.break_statement),

        _chunk: ($) =>
            choice(
                seq(one_or_more($._statement), optional($._last_statement)),
                $._last_statement
            ),

        _block: ($) => $._chunk,

        _expression: ($) =>
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
                $.unary_operation
            ),

        // Primitives {{{
        nil: (_) => "nil",

        boolean: (_) => choice("true", "false"),

        number: (_) => /[0-9]+/,

        _inner_string: (_) => /[a-zA-Z0-9_ ]+/,

        // string: ($) => prec.left($.multi_string),
        // basic_string_style("'"),
        // basic_string_style('"'),

        // ...[...Array(EQUALS_LEVELS).keys()].map((level) =>
        //     lua_string_level(level)
        // )

        ellipsis: (_) => "...",

        function_name: ($) =>
            seq(
                list_of($.identifier, alias(".", $.table_dot), false),
                optional(seq(alias(":", $.table_colon), $.identifier))
            ),

        function: ($) =>
            seq(
                $.function_start,
                // TODO: It's weird that we're capturing this white space in the name of functions.
                /\s*/,
                $.function_body
            ),

        function_body: ($) =>
            seq(
                alias($.left_paren, $.function_body_paren),
                optional($.parameter_list),
                alias($.right_paren, $.function_body_paren),
                field("body", optional($._block)),
                alias("end", $.function_end)
            ),

        parameter_list: ($) =>
            choice(
                seq(
                    $._identifier_list,
                    // TODO: Why does the regex work here,
                    // but when we use the literal string and ellipsis,
                    // it just gives us an error?
                    alias(optional(/\s*,\s*\.\.\./), $.ellipsis)
                ),
                $.ellipsis
            ),

        // }}}

        _expression_list: ($) => list_of($._expression, ","),

        binary_operation: ($) =>
            choice(
                ...[
                    ["or", PREC.OR],
                    ["and", PREC.AND],
                    ["<", PREC.COMPARE],
                    ["<=", PREC.COMPARE],
                    ["==", PREC.COMPARE],
                    ["~=", PREC.COMPARE],
                    [">=", PREC.COMPARE],
                    [">", PREC.COMPARE],
                    ["|", PREC.BIT_OR],
                    ["~", PREC.BIT_NOT],
                    ["&", PREC.BIT_AND],
                    ["<<", PREC.SHIFT],
                    [">>", PREC.SHIFT],
                    ["+", PREC.PLUS],
                    ["-", PREC.PLUS],
                    ["*", PREC.MULTI],
                    ["/", PREC.MULTI],
                    ["//", PREC.MULTI],
                    ["%", PREC.MULTI],
                ].map(([operator, precedence]) =>
                    prec.left(
                        precedence,
                        seq($._expression, operator, $._expression)
                    )
                ),
                ...[
                    ["..", PREC.CONCAT],
                    ["^", PREC.POWER],
                ].map(([operator, precedence]) =>
                    prec.right(
                        precedence,
                        seq($._expression, operator, $._expression)
                    )
                )
            ),

        unary_operation: ($) =>
            prec.left(
                PREC.UNARY,
                seq(choice("not", "#", "-", "~"), $._expression)
            ),

        local: (_) => "local",

        variable_declaration: ($) =>
            prec.right(
                PREC.DEFAULT,
                seq(
                    field("documentation", optional($.emmy_documentation)),
                    optional($.local),
                    list_of(field("name", $.variable_declarator), ",", false),
                    optional(
                        seq(
                            "=",
                            list_of(field("value", $._expression), ",", false)
                        )
                    )
                )
            ),

        // TODO: Fix that one test
        // variable_declaration: ($) =>
        //     prec.right(
        //         PREC.PRIORITY,
        //         seq(
        //             field("documentation", optional($.emmy_documentation)),
        //             optional($.local),
        //             field("name", $.variable_declarator),
        //             any_amount_of(",", field("name", $.variable_declarator)),
        //             optional(
        //                 seq(
        //                     "=",
        //                     field("value", $._expression),
        //                     any_amount_of(",", field("value", $._expression))
        //                 )
        //             )
        //         )
        //     ),

        variable_declarator: ($) => $._var,

        // var ::=  identifier | prefixexp `[´ exp `]´ | prefixexp `.´ identifier
        _var: ($) =>
            prec(
                PREC.PRIORITY,
                choice(
                    $.identifier,
                    seq($.prefix_exp, "[", $._expression, "]"),
                    seq($.prefix_exp, ".", $.identifier)
                )
            ),

        var_list: ($) => list_of($._var, ",", false),

        _identifier_list: ($) =>
            prec.right(PREC.COMMA, list_of($.identifier, ",", false)),

        return_statement: ($) =>
            prec(
                PREC.PRIORITY,
                seq("return", optional(list_of($._expression, ",")))
            ),

        break_statement: (_) => "break",

        // Blocks {{{
        do_statement: ($) =>
            seq(alias("do", $.do_start), $._block, alias("end", $.do_end)),

        while_statement: ($) =>
            seq(
                alias("while", $.while_start),
                $._expression,
                alias("do", $.while_do),
                $._block,
                alias("end", $.while_end)
            ),

        repeat_statement: ($) =>
            seq(
                alias("repeat", $.repeat_start),
                $._block,
                alias("until", $.repeat_until),
                $._expression
            ),

        if_statement: ($) =>
            seq(
                alias("if", $.if_start),
                $._expression,
                alias("then", $.if_then),
                $._block,
                any_amount_of(
                    seq(
                        alias("elseif", $.if_elseif),
                        $._expression,
                        alias("then", $.if_then),
                        $._block
                    )
                ),
                optional(seq(alias("else", $.if_else), $._block)),
                alias("end", $.if_end)
            ),

        for_statement: ($) =>
            seq(
                alias("for", $.for_start),
                choice($.for_numeric, $.for_generic),
                alias("do", $.for_do),
                $._block,
                alias("end", $.for_end)
            ),

        for_numeric: ($) =>
            seq(
                field("var", $.identifier),
                "=",
                field("start", $._expression),
                ",",
                field("finish", $._expression),
                optional(seq(",", field("step", $._expression)))
            ),

        for_generic: ($) =>
            seq(
                field(
                    "identifier_list",
                    alias($._identifier_list, $.identifier_list)
                ),
                alias("in", $.for_in),
                field("expression_list", $._expression_list)
            ),

        function_start: () => "function",

        function_statement: ($) =>
            seq(
                field("documentation", optional($.emmy_documentation)),
                choice(
                    seq(
                        alias("local", $.local),
                        $.function_start,
                        /\s*/,
                        field("name", $.identifier)
                    ),
                    seq($.function_start, /\s*/, field("name", $.function_name))
                ),
                $.function_body
            ),

        // }}}

        // Table {{{
        tableconstructor: ($) => seq("{", optional($.fieldlist), "}"),

        fieldlist: ($) =>
            prec(PREC.COMMA, list_of($.field, $.field_separator, true)),

        field: ($) => $._field_expression,

        // `[´ exp `]´ `=´ exp | identifier `=´ exp | exp
        _named_field_expression: ($) =>
            prec(
                PREC.PRIORITY,
                seq(
                    field("name", $.identifier),
                    "=",
                    field("value", $._expression)
                )
            ),

        _expression_field_expression: ($) =>
            prec(
                PREC.PRIORITY,
                seq(
                    // TODO: Decide if we really want to keep these...
                    //          It will be useful when we want to highlight them
                    //          in a particular color for people :)
                    field(
                        "field_left_bracket",
                        alias($.left_bracket, $.field_left_bracket)
                    ),
                    field("key", $._expression),
                    field(
                        "field_right_bracket",
                        alias($.right_bracket, $.field_right_bracket)
                    ),
                    "=",
                    field("value", $._expression)
                )
            ),

        _field_expression: ($) =>
            choice(
                $._expression_field_expression,
                $._named_field_expression,
                field("value", $._expression)
            ),

        field_separator: (_) => choice(",", ";"),
        // }}}

        // Function {{{
        _prefix_exp: ($) =>
            choice(
                $._var,
                $.function_call,
                seq($.left_paren, $._expression, $.right_paren)
            ),

        prefix_exp: ($) => $._prefix_exp,

        function_call: ($) =>
            prec.right(
                PREC.FUNCTION,
                seq(
                    field("prefix", $.prefix_exp),
                    choice($._args, $._self_call)
                )
            ),

        _args: ($) =>
            choice($._parentheses_call, $._table_call, $._string_call),

        _parentheses_call: ($) =>
            seq(
                alias($.left_paren, $.function_call_paren),
                field("args", optional($.function_arguments)),
                alias($.right_paren, $.function_call_paren)
            ),

        _string_call: ($) =>
            field(
                "args",
                // TODO: Decide if this is really the name we want to use.
                alias($.string, $.string_argument)
            ),

        _table_call: ($) =>
            field("args", alias($.tableconstructor, $.table_argument)),

        _self_call: ($) =>
            seq(alias(":", $.self_call_colon), $.identifier, $._args),

        function_arguments: ($) =>
            seq($._expression, optional(repeat(seq(",", $._expression)))),

        // }}}

        identifier: (_) => /[a-zA-Z_][a-zA-Z0-9_]*/,

        // Dummy Fields {{{
        left_paren: (_) => "(",
        right_paren: (_) => ")",

        left_bracket: (_) => "[",
        right_bracket: (_) => "]",

        _comma: (_) => ",",
        // }}}

        // Documentation {{{
        documentation_tag: () => /[^\n]*/,
        _documentation_tag_container: ($) =>
            prec.right(PREC.PROGRAM, seq(/\s*---@tag\s+/, $.documentation_tag)),

        documentation_brief: () => /[^\n]*/,
        _documentation_brief_container: ($) =>
            prec.right(
                PREC.PROGRAM,
                seq(
                    /\s*---@brief \[\[/,
                    any_amount_of(/\s*---/, $.documentation_brief),
                    /\s*---@brief \]\]/
                )
            ),

        emmy_ignore: () => /---\n/,
        emmy_comment: ($) =>
            token(prec.right(repeat1(choice(/---[^@\n]*\n/, /---\n/)))),

        emmy_type_list: ($) => seq(field("type", $.emmy_type), "[]"),
        emmy_type_map: ($) =>
            seq(
                "table<",
                field("key", $.emmy_type),
                ",",
                field("value", $.emmy_type),
                ">"
            ),

        emmy_type: ($) =>
            choice($.emmy_type_map, $.emmy_type_list, $.identifier),

        // Definition:
        // ---@param param_name MY_TYPE[|other_type] [@comment]
        //
        // I don't think this is needed (read this as: I hate it)
        // ---@param example table @this is my comment hello
        //
        // ---@param example table hello
        // ---@param example (table): hello
        emmy_parameter: ($) =>
            seq(
                /\s*---@param\s+/,
                field("name", $.identifier),
                field("type", list_of($.emmy_type, /\s*\|\s*/)),

                // TODO: How closely should we be to emmy...
                optional(
                    seq(
                        /\s*:\s*/,
                        field("description", $.parameter_description)
                    )
                ),
                /\n\s*/
            ),

        _multiline_emmy_string: ($) =>
            prec.right(
                PREC.PRIORITY,
                seq(/[^\n]+/, any_amount_of(/\s*---[^\n]*/))
                // seq(/[^\n]*/, any_amount_of(/\n\s*---[^\n]*/))
            ),

        parameter_description: ($) => $._multiline_emmy_string,

        emmy_return_description: ($) => $._multiline_emmy_string,
        emmy_return_description: ($) => /[^\n]*/,

        emmy_return: ($) =>
            seq(
                /---@return/,
                field("type", list_of($.emmy_type, "|")),
                // field("description", optional($.emmy_return_description))
                // field("description", optional(/[^\n]+/))
                field("description", $.emmy_return_description)
            ),

        emmy_eval: ($) => $._expression,
        _emmy_eval_container: ($) => seq(/---@eval\s+/, $.emmy_eval),

        emmy_see: (_) => seq(/---@see\s+/, /[^\n]*/),
        emmy_usage: (_) => seq(/---@usage\s+/, /[^\n]*/),
        emmy_todo: (_) => seq(/---@todo\s+/, /[^\n]*/),
        emmy_varargs: (_) => seq(/---@varargs\s+/, /[^\n]*/),

        emmy_documentation: ($) =>
            prec.left(
                PREC.DEFAULT,
                seq(
                    alias($.emmy_comment, $.emmy_header),
                    any_amount_of(
                        choice(
                            $.emmy_ignore,
                            $._emmy_eval_container,
                            $.emmy_parameter,
                            $.emmy_see,
                            $.emmy_todo,
                            $.emmy_usage,
                            $.emmy_varargs,
                            $.emmy_return
                        )
                    )
                )
            ),
        // }}}

        // Comments {{{
        comment: ($) => choice(seq("--", /[^-].*\r?\n/), $._multi_comment),
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
    return trailing
        ? seq(match, any_amount_of(sep, match), optional(sep))
        : seq(match, any_amount_of(sep, match));
}

/*
   ambient_declaration: $ => seq(
        'declare',
        choice(
          $._declaration,
          seq('global', $.statement_block),
          seq('module', '.', alias($.identifier, $.property_identifier), ':', $._type)
        )
      ),

    member_expression: $ => prec(PREC.MEMBER, seq(
      field('object', choice($._expression, $._primary_expression)),
      choice('.', '?.'),
      field('property', alias($.identifier, $.property_identifier))
    )),

    */
