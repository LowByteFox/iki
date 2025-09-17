/* SPDX-License-Identifier: BSD-2-Clause */
module iki::lexer;

import std::io;

faultdef TOO_LONG, NO_TOKEN, BAD_TOKEN;

enum TokenType {
    TEXT_LITERAL,
    EXPR_START,
    EXPR_END,
    STMT_START,
    STMT_END,
}

struct Token (Printable) {
    TokenType type;
    char[] view;
    int offset;
}

struct Lexer {
    char[] buffer;
    int offset;
}

fn Token? next(Lexer *lex)
{
    if (lex.offset < 0) return TOO_LONG?;

    char current = next_char(lex)!;

    switch {
        case current == '#':
            if (peek(lex)! == '{') {
                defer lex.offset++;
                return { EXPR_START, "#{", lex.offset - 1 };
            }
            nextcase;
        case current == '}':
            if (peek(lex)! == '}') {
                defer lex.offset++;
                return { STMT_END, "}}", lex.offset - 1 };
            } else {
                return { EXPR_END, "}", lex.offset - 1 };
            }
        case current == '{':
            if (peek(lex)! == '{') {
                defer lex.offset++;
                return { STMT_START, "{{", lex.offset - 1 };
            }
    }

    return lex_text(lex);
}

fn usz? Token.to_format(&self, Formatter* formatter) @dynamic
{
	return formatter.printf("{ type: %s, view: \"%s\" }", self.type,
        (String) self.view);
}


fn Token? lex_text(Lexer *lex) @local
{
    int start = lex.offset - 1;
    char peeked = ' ';

    while ((peeked = peek(lex)!) && peeked != '#' && peeked != '{' &&
        peeked != '}') {
        if (peek(lex)! == '\\') lex.offset++;
        lex.offset++;
        if (lex.offset >= lex.buffer.len) break;
        peeked = lex.buffer[lex.offset];
    };

    if (lex.offset > lex.buffer.len) lex.offset = lex.buffer.len;

    return { TEXT_LITERAL, lex.buffer[start..lex.offset - 1], start };
}

fn char? next_char(Lexer *lex) @local
{
    if (lex.offset < 0) return TOO_LONG?;

    if (lex.offset == lex.buffer.len) return NO_TOKEN?;
    defer lex.offset++;

    return lex.buffer[lex.offset];
}

fn char? peek(Lexer *lex) @local
{
    if (lex.offset < 0) return TOO_LONG?;

    if (lex.offset == lex.buffer.len) return 0;
    return lex.buffer[lex.offset];
}
