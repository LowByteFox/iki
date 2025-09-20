/* SPDX-License-Identifier: BSD-2-Clause */
module iki::codegen;

import std::core::dstring, std::collections::list, std::io, std::core::ascii;
import iki::lexer;

enum Mode {
    C,
    C3
}

fn String? gen(Allocator alloc, String source, String content, Mode mode)
{
    DString str_builder;
    List{bool} stack;
    usz in_code = 0;
    Lexer lex = { content, 0 };
    str_builder.init(alloc);

    @pool() {
        stack.tinit();

        fn_base(&str_builder, source, mode);

        while (try Token tok = lexer::next(&lex)) {
            switch (tok.type) {
            case TEXT_LITERAL:
            case EXPR_END:
                if (in_code > 0) {
                    str_builder.append_chars((String) tok.view);
                } else {
                    append_text(&str_builder, (String) tok.view, mode);
                }
            case EXPR_START:
                Token fmt = lexer::next(&lex)!;
                if (lexer::next(&lex)!.type != EXPR_END) abort("Expected }!");

                append_printf(&str_builder, (String) fmt.view, mode);
            case STMT_START:
                String body = (String) lexer::next(&lex)!.view;
                if (lexer::next(&lex)!.type != STMT_END) abort("Expected }}!");
                String trimmed = body.trim();
                if (trimmed == "code") {
                    stack.push(false);
                    in_code++;
                } else if (trimmed == "end") {
                    bool end = stack.pop()!;
                    str_builder.append_chars(end ? "}\n" : "");

                    if (in_code > 0) in_code--;
                } else {
                    stack.push(true);
                    str_builder.append_chars(body);
                    str_builder.append_chars("{\n");
                }
            default:
                io::printn(tok.type);
                abort("token type not implemented yet!");
            }
        }

        fn_end(&str_builder, mode);
    };

    return str_builder.str_view();
}

fn String? tgen(String source, String content, Mode mode) =>
    gen(tmem, source, content, mode);

fn void fn_base(DString *builder, String name, Mode mode) @local
{
    switch {
    case mode == C3:
        builder.appendf(`fn String? %s(Allocator __alloc) {
DString __str_builder;
__str_builder.init(__alloc);
`, name);
    default:
        abort("this mode is not implemented yet!");
    }
}

fn void fn_end(DString *builder, Mode mode) @local
{
    switch {
    case mode == C3:
        builder.append_chars(`return __str_builder.str_view();
}
`);
    default:
        abort("this mode is not implemented yet!");
    }
}

fn void append_text(DString *builder, String text, Mode mode) @local
{
    if (is_empty(text)) return;

    switch {
    case mode == C3:
        builder.appendf("__str_builder.append_chars(`%s`);\n", text);
    default:
        abort("this mode is not implemented yet!");
    }
}

fn void append_printf(DString *builder, String text, Mode mode) @local
{
    switch {
    case mode == C3:
        builder.appendf("__str_builder.appendf(%s);\n", text.trim());
    default:
        abort("this mode is not implemented yet!");
    }
}

fn bool is_empty(String str)
{
    return str.count("\n") == str.len;
}
