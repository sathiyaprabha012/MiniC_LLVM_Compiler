#ifndef MINIC_TOKEN_LOG_H
#define MINIC_TOKEN_LOG_H

#include <stdio.h>

/* Global handle to tokens.txt — opened once in main(), used by the lexer */
extern FILE *token_log_fp;

/* Writes one line to tokens.txt: <line_number> <TOKEN_NAME> [<lexeme>] */
void log_token(int line, const char *token_name, const char *lexeme);

#endif /* MINIC_TOKEN_LOG_H */
