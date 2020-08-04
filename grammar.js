module.exports = grammar({
  name: 'lua',

  extras: $ => [/[\s\n]/],
  inline: $ => [
    $._statement,
  ],

  rules: {

    program: $ => $.return_statement,

    _statement: $ => choice(
      choice(
        $.number,
        $.string,
        $.identifier,
      ),
    ),

    return_statement: $ => seq(
      "return",
      $._statement
    ),

    number: $ => /[0-9]+/,

    string: $ => seq(
      '"',
      /[a-zA-Z0-9_]+/,
      '"',
    ),

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/
  },
});
