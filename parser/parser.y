/* ============================================================
   MiniC-LLVM-Compiler — Parser (Bison grammar specification)
   ============================================================ */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "types.h"
#include "error.h"

extern int yylex(void);
extern int yylineno;
extern char *yytext;
void yyerror(const char *msg);

/* Root of the AST, populated once parsing finishes successfully */
ASTNode *ast_root = NULL;
%}

%union {
    ASTNode *ast_node;
    char    *str;
    int      dtype;
}

/* ---- Tokens ---- */
%token <ast_node> IDENTIFIER INT_LITERAL FLOAT_LITERAL CHAR_LITERAL BOOL_LITERAL
%token INT KW_FLOAT KW_CHAR KW_BOOL IF ELSE WHILE FOR RETURN
%token PLUS MINUS STAR SLASH PERCENT ASSIGN
%token LT GT LE GE EQ NE AND OR NOT
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET SEMI COMMA

/* ---- Non-terminal types ---- */
%type <ast_node> program func_decl_list func_decl param_list param_list_opt param
%type <ast_node> block stmt_list stmt
%type <ast_node> var_decl array_decl
%type <ast_node> if_stmt while_stmt for_stmt return_stmt expr_stmt
%type <ast_node> expr assign_expr logical_or_expr logical_and_expr
%type <ast_node> equality_expr relational_expr additive_expr term unary_expr postfix_expr primary_expr
%type <ast_node> arg_list arg_list_opt
%type <dtype> type_spec

/* ---- Precedence (lowest to highest) ---- */
%right ASSIGN
%left OR
%left AND
%left EQ NE
%left LT GT LE GE
%left PLUS MINUS
%left STAR SLASH PERCENT
%right NOT UMINUS
%left LPAREN RPAREN LBRACKET RBRACKET

%start program

%%

/* ============================================================
   Program structure
   ============================================================ */

program
    : func_decl_list
        {
            $$ = create_node(NODE_PROGRAM, 1, NULL);
            for (int i = 0; i < $1->num_children; i++) {
                add_child($$, $1->children[i]);
            }
            /* the wrapper node $1 itself is discarded (its children were re-parented) */
            free($1->children);
            free($1);
            ast_root = $$;
        }
    ;

func_decl_list
    : func_decl_list func_decl
        { add_child($1, $2); $$ = $1; }
    | func_decl
        { $$ = create_node(NODE_PROGRAM, yylineno, NULL); add_child($$, $1); }
    ;

func_decl
    : type_spec IDENTIFIER LPAREN param_list_opt RPAREN block
        {
            $$ = create_node(NODE_FUNC_DECL, @1.first_line ? @1.first_line : yylineno, $2->str_value);
            $$->data_type = $1;
            add_child($$, $4);   /* params */
            add_child($$, $6);   /* body block */
            free_ast($2);        /* identifier node consumed into str_value above, node itself discarded */
        }
    ;

param_list_opt
    : param_list   { $$ = $1; }
    | /* empty */  { $$ = create_node(NODE_PARAM_LIST, yylineno, NULL); }
    ;

param_list
    : param_list COMMA param
        { add_child($1, $3); $$ = $1; }
    | param
        { $$ = create_node(NODE_PARAM_LIST, yylineno, NULL); add_child($$, $1); }
    ;

param
    : type_spec IDENTIFIER
        {
            $$ = create_node(NODE_PARAM, yylineno, $2->str_value);
            $$->data_type = $1;
            free_ast($2);
        }
    | type_spec IDENTIFIER LBRACKET RBRACKET
        {
            $$ = create_node(NODE_PARAM, yylineno, $2->str_value);
            $$->data_type = $1;
            $$->int_value = 1; /* flag: array parameter */
            free_ast($2);
        }
    ;

type_spec
    : INT        { $$ = TYPE_INT; }
    | KW_FLOAT   { $$ = TYPE_FLOAT; }
    | KW_CHAR    { $$ = TYPE_CHAR; }
    | KW_BOOL    { $$ = TYPE_BOOL; }
    ;

/* ============================================================
   Blocks and statements
   ============================================================ */

block
    : LBRACE stmt_list RBRACE   { $$ = $2; }
    | LBRACE RBRACE             { $$ = create_node(NODE_BLOCK, yylineno, NULL); }
    ;

stmt_list
    : stmt_list stmt   { add_child($1, $2); $$ = $1; }
    | stmt             { $$ = create_node(NODE_BLOCK, yylineno, NULL); add_child($$, $1); }
    ;

stmt
    : var_decl SEMI       { $$ = $1; }
    | array_decl SEMI     { $$ = $1; }
    | expr_stmt SEMI      { $$ = $1; }
    | if_stmt              { $$ = $1; }
    | while_stmt            { $$ = $1; }
    | for_stmt                { $$ = $1; }
    | return_stmt SEMI         { $$ = $1; }
    | block                      { $$ = $1; }
    | error SEMI
        {
            report_syntax_error(yylineno, "invalid statement, skipping to next ';'");
            $$ = create_node(NODE_BLOCK, yylineno, NULL); /* empty placeholder so tree stays valid */
        }
    ;

var_decl
    : type_spec IDENTIFIER
        { $$ = create_node(NODE_VAR_DECL, yylineno, $2->str_value); $$->data_type = $1; free_ast($2); }
    | type_spec IDENTIFIER ASSIGN expr
        {
            $$ = create_node(NODE_VAR_DECL, yylineno, $2->str_value);
            $$->data_type = $1;
            add_child($$, $4);
            free_ast($2);
        }
    ;

array_decl
    : type_spec IDENTIFIER LBRACKET INT_LITERAL RBRACKET
        {
            $$ = create_node(NODE_ARRAY_DECL, yylineno, $2->str_value);
            $$->data_type = $1;
            add_child($$, $4);  /* size literal, used by semantic analysis / codegen */
            free_ast($2);
        }
    ;

if_stmt
    : IF LPAREN expr RPAREN stmt
        { $$ = create_node(NODE_IF, yylineno, NULL); add_child($$, $3); add_child($$, $5); }
    | IF LPAREN expr RPAREN stmt ELSE stmt
        { $$ = create_node(NODE_IF, yylineno, NULL); add_child($$, $3); add_child($$, $5); add_child($$, $7); }
    ;

while_stmt
    : WHILE LPAREN expr RPAREN stmt
        { $$ = create_node(NODE_WHILE, yylineno, NULL); add_child($$, $3); add_child($$, $5); }
    ;

for_stmt
    : FOR LPAREN expr_stmt SEMI expr SEMI expr_stmt RPAREN stmt
        {
            $$ = create_node(NODE_FOR, yylineno, NULL);
            add_child($$, $3); add_child($$, $5); add_child($$, $7); add_child($$, $9);
        }
    | FOR LPAREN var_decl SEMI expr SEMI expr_stmt RPAREN stmt
        {
            $$ = create_node(NODE_FOR, yylineno, NULL);
            add_child($$, $3); add_child($$, $5); add_child($$, $7); add_child($$, $9);
        }
    ;

return_stmt
    : RETURN expr   { $$ = create_node(NODE_RETURN, yylineno, NULL); add_child($$, $2); }
    | RETURN        { $$ = create_node(NODE_RETURN, yylineno, NULL); }
    ;

expr_stmt
    : expr          { $$ = create_node(NODE_EXPR_STMT, yylineno, NULL); add_child($$, $1); }
    | /* empty */   { $$ = create_node(NODE_EXPR_STMT, yylineno, NULL); }
    ;

/* ============================================================
   Expressions (precedence climbing via grammar layering)
   ============================================================ */

expr
    : assign_expr   { $$ = $1; }
    ;

assign_expr
    : IDENTIFIER ASSIGN assign_expr
        { $$ = create_node(NODE_ASSIGN, yylineno, $1->str_value); add_child($$, $3); free_ast($1); }
    | IDENTIFIER LBRACKET expr RBRACKET ASSIGN assign_expr
        {
            ASTNode *target = create_node(NODE_ARRAY_ACCESS, yylineno, $1->str_value);
            add_child(target, $3);
            free_ast($1);
            $$ = create_node(NODE_ASSIGN, yylineno, NULL);
            add_child($$, target);
            add_child($$, $6);
        }
    | logical_or_expr   { $$ = $1; }
    ;

logical_or_expr
    : logical_or_expr OR logical_and_expr
        { $$ = create_node(NODE_LOGICAL, yylineno, "||"); add_child($$, $1); add_child($$, $3); }
    | logical_and_expr   { $$ = $1; }
    ;

logical_and_expr
    : logical_and_expr AND equality_expr
        { $$ = create_node(NODE_LOGICAL, yylineno, "&&"); add_child($$, $1); add_child($$, $3); }
    | equality_expr   { $$ = $1; }
    ;

equality_expr
    : equality_expr EQ relational_expr
        { $$ = create_node(NODE_COMPARE, yylineno, "=="); add_child($$, $1); add_child($$, $3); }
    | equality_expr NE relational_expr
        { $$ = create_node(NODE_COMPARE, yylineno, "!="); add_child($$, $1); add_child($$, $3); }
    | relational_expr   { $$ = $1; }
    ;

relational_expr
    : relational_expr LT additive_expr
        { $$ = create_node(NODE_COMPARE, yylineno, "<"); add_child($$, $1); add_child($$, $3); }
    | relational_expr GT additive_expr
        { $$ = create_node(NODE_COMPARE, yylineno, ">"); add_child($$, $1); add_child($$, $3); }
    | relational_expr LE additive_expr
        { $$ = create_node(NODE_COMPARE, yylineno, "<="); add_child($$, $1); add_child($$, $3); }
    | relational_expr GE additive_expr
        { $$ = create_node(NODE_COMPARE, yylineno, ">="); add_child($$, $1); add_child($$, $3); }
    | additive_expr   { $$ = $1; }
    ;

additive_expr
    : additive_expr PLUS term
        { $$ = create_node(NODE_BINOP, yylineno, "+"); add_child($$, $1); add_child($$, $3); }
    | additive_expr MINUS term
        { $$ = create_node(NODE_BINOP, yylineno, "-"); add_child($$, $1); add_child($$, $3); }
    | term   { $$ = $1; }
    ;

term
    : term STAR unary_expr
        { $$ = create_node(NODE_BINOP, yylineno, "*"); add_child($$, $1); add_child($$, $3); }
    | term SLASH unary_expr
        { $$ = create_node(NODE_BINOP, yylineno, "/"); add_child($$, $1); add_child($$, $3); }
    | term PERCENT unary_expr
        { $$ = create_node(NODE_BINOP, yylineno, "%"); add_child($$, $1); add_child($$, $3); }
    | unary_expr   { $$ = $1; }
    ;

unary_expr
    : MINUS unary_expr %prec UMINUS
        { $$ = create_node(NODE_UNARYOP, yylineno, "-"); add_child($$, $2); }
    | NOT unary_expr
        { $$ = create_node(NODE_UNARYOP, yylineno, "!"); add_child($$, $2); }
    | postfix_expr   { $$ = $1; }
    ;

postfix_expr
    : primary_expr   { $$ = $1; }
    | IDENTIFIER LBRACKET expr RBRACKET
        { $$ = create_node(NODE_ARRAY_ACCESS, yylineno, $1->str_value); add_child($$, $3); free_ast($1); }
    | IDENTIFIER LPAREN arg_list_opt RPAREN
        {
            $$ = create_node(NODE_FUNC_CALL, yylineno, $1->str_value);
            for (int i = 0; i < $3->num_children; i++) add_child($$, $3->children[i]);
            free($3->children); free($3);
            free_ast($1);
        }
    ;

arg_list_opt
    : arg_list      { $$ = $1; }
    | /* empty */   { $$ = create_node(NODE_PARAM_LIST, yylineno, NULL); }
    ;

arg_list
    : arg_list COMMA expr
        { add_child($1, $3); $$ = $1; }
    | expr
        { $$ = create_node(NODE_PARAM_LIST, yylineno, NULL); add_child($$, $1); }
    ;

primary_expr
    : IDENTIFIER         { $$ = $1; }
    | INT_LITERAL        { $$ = $1; }
    | FLOAT_LITERAL       { $$ = $1; }
    | CHAR_LITERAL          { $$ = $1; }
    | BOOL_LITERAL            { $$ = $1; }
    | LPAREN expr RPAREN        { $$ = $2; }
    ;

%%

void yyerror(const char *msg) {
    report_syntax_error(yylineno, msg);
}
