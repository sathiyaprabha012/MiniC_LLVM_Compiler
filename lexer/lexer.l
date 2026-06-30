/* ============================================================
   MiniC-LLVM-Compiler — Lexical Analyzer (Flex specification)
   ============================================================ */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "parser.tab.h"
#include "tokens.h"
#include "error.h"

/* yylval is how the lexer hands literal/identifier values to Bison */
extern YYSTYPE yylval;
%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INTLIT      {DIGIT}+
FLOATLIT    {DIGIT}+"."{DIGIT}+
CHARLIT     '(\\.|[^\\'])'

%%

"//"[^\n]*                 { /* single-line comment, ignored */ }
"/*"([^*]|\*+[^*/])*\*+"/"  { /* multi-line comment, ignored */ }

"int"                       { log_token(yylineno, "INT", yytext);    return INT; }
"float"                     { log_token(yylineno, "KW_FLOAT", yytext); return KW_FLOAT; }
"char"                      { log_token(yylineno, "KW_CHAR", yytext);  return KW_CHAR; }
"bool"                      { log_token(yylineno, "KW_BOOL", yytext);  return KW_BOOL; }
"if"                        { log_token(yylineno, "IF", yytext);     return IF; }
"else"                      { log_token(yylineno, "ELSE", yytext);   return ELSE; }
"while"                     { log_token(yylineno, "WHILE", yytext);  return WHILE; }
"for"                       { log_token(yylineno, "FOR", yytext);    return FOR; }
"return"                    { log_token(yylineno, "RETURN", yytext); return RETURN; }
"true"                      { log_token(yylineno, "BOOL_LITERAL", yytext);
                               yylval.ast_node = create_bool_literal(1, yylineno);
                               return BOOL_LITERAL; }
"false"                     { log_token(yylineno, "BOOL_LITERAL", yytext);
                               yylval.ast_node = create_bool_literal(0, yylineno);
                               return BOOL_LITERAL; }

{FLOATLIT}                  { log_token(yylineno, "FLOAT_LITERAL", yytext);
                               yylval.ast_node = create_float_literal((float)atof(yytext), yylineno);
                               return FLOAT_LITERAL; }

{INTLIT}                    { log_token(yylineno, "INT_LITERAL", yytext);
                               yylval.ast_node = create_int_literal(atoi(yytext), yylineno);
                               return INT_LITERAL; }

{CHARLIT}                   { log_token(yylineno, "CHAR_LITERAL", yytext);
                               char val = (yytext[1] == '\\') ? yytext[2] : yytext[1];
                               yylval.ast_node = create_char_literal(val, yylineno);
                               return CHAR_LITERAL; }

{ID}                        { log_token(yylineno, "IDENTIFIER", yytext);
                               yylval.ast_node = create_identifier(yytext, yylineno);
                               return IDENTIFIER; }

"+"                          { log_token(yylineno, "PLUS", yytext);    return PLUS; }
"-"                          { log_token(yylineno, "MINUS", yytext);   return MINUS; }
"*"                          { log_token(yylineno, "STAR", yytext);    return STAR; }
"/"                          { log_token(yylineno, "SLASH", yytext);   return SLASH; }
"%"                          { log_token(yylineno, "PERCENT", yytext); return PERCENT; }

"<="                         { log_token(yylineno, "LE", yytext); return LE; }
">="                         { log_token(yylineno, "GE", yytext); return GE; }
"=="                         { log_token(yylineno, "EQ", yytext); return EQ; }
"!="                         { log_token(yylineno, "NE", yytext); return NE; }
"<"                           { log_token(yylineno, "LT", yytext); return LT; }
">"                           { log_token(yylineno, "GT", yytext); return GT; }
"="                           { log_token(yylineno, "ASSIGN", yytext); return ASSIGN; }

"&&"                          { log_token(yylineno, "AND", yytext); return AND; }
"||"                          { log_token(yylineno, "OR", yytext);  return OR; }
"!"                            { log_token(yylineno, "NOT", yytext); return NOT; }

"("                            { log_token(yylineno, "LPAREN", yytext);   return LPAREN; }
")"                            { log_token(yylineno, "RPAREN", yytext);   return RPAREN; }
"{"                            { log_token(yylineno, "LBRACE", yytext);   return LBRACE; }
"}"                            { log_token(yylineno, "RBRACE", yytext);   return RBRACE; }
"["                            { log_token(yylineno, "LBRACKET", yytext); return LBRACKET; }
"]"                            { log_token(yylineno, "RBRACKET", yytext); return RBRACKET; }
";"                            { log_token(yylineno, "SEMI", yytext);     return SEMI; }
","                            { log_token(yylineno, "COMMA", yytext);   return COMMA; }

[ \t\r]+                      { /* whitespace, ignored */ }
\n                              { /* newline, yylineno auto-incremented by %option yylineno */ }

.                                {
    char msg[64];
    snprintf(msg, sizeof(msg), "unexpected character '%s'", yytext);
    report_lex_error(yylineno, msg);
}

%%
