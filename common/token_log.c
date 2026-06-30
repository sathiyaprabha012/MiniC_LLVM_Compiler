#include "tokens.h"

FILE *token_log_fp = NULL;

void log_token(int line, const char *token_name, const char *lexeme) {
    if (token_log_fp == NULL) return;  /* logging disabled if file wasn't opened */
    if (lexeme != NULL) {
        fprintf(token_log_fp, "%-6d %-15s %s\n", line, token_name, lexeme);
    } else {
        fprintf(token_log_fp, "%-6d %-15s\n", line, token_name);
    }
}
