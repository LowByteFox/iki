/* SPDX-License-Identifier: BSD-2-Clause */
module lexer_test;

import std::collections::list;
import iki::lexer;

fn void text_simple() @test => @pool()
{
    test::eq(
        ttokenize("Hello, World!\n"),
        (Token[]) {
            {TEXT_LITERAL, "Hello, World!\n", 0}
        },
    );
}

fn void expr_simple() @test => @pool()
{
    test::eq(
        ttokenize("#{ xyz }"),
        (Token[]) {
            {EXPR_START, "#{", 0},
            {TEXT_LITERAL, " xyz ", 0},
            {EXPR_END, "}", 0},
        },
    );
}

fn void text_end_expr() @test => @pool()
{
    test::eq(
        ttokenize("a}"),
        (Token[]) {
            {TEXT_LITERAL, "a", 0},
            {EXPR_END, "}", 0},
        },
    );
}

fn void text_end_expr_newline() @test => @pool()
{
    test::eq(
        ttokenize(`
#{`),
        (Token[]) {
            {TEXT_LITERAL, "\n", 0},
            {EXPR_START, "#{", 0},
        },
    );
}

fn void test_stmt() @test => @pool()
{
    test::eq(
        ttokenize("{{ code }}"),
        (Token[]) {
            {STMT_START, "{{", 0},
            {TEXT_LITERAL, " code ", 0},
            {STMT_END, "}}", 0},
        },
    );
}

fn void test_stmt_end_expr_end() @test => @pool()
{
    test::eq(
        ttokenize("\nfoo\n{{ end }}}"),
        (Token[]) {
            {TEXT_LITERAL, "\nfoo\n", 0},
            {STMT_START, "{{", 0},
            {TEXT_LITERAL, " end ", 0},
            {STMT_END, "}}", 0},
            {EXPR_END, "}", 0},
        },
    );
}


fn Token[] ttokenize(String code)
{
    List{Token} toks;

    toks.tinit();
    Lexer lex = { code, 0 };

    while (try Token t = lexer::next(&lex)) toks.push(t);

    return toks.to_tarray();
}


fn bool Token.equals(&self, Token other) @operator(==)
{
    return self.view == other.view && self.type == other.type;
}
