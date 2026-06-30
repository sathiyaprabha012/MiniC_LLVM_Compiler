#include <stdio.h>
#include "error.h"

int error_count = 0;
int warning_count = 0;

void report_lex_error(int line, const char *message) {
    fprintf(stderr, "lexical error: line %d: %s\n", line, message);
    error_count++;
}

void report_syntax_error(int line, const char *message) {
    fprintf(stderr, "syntax error: line %d: %s\n", line, message);
    error_count++;
}

void report_semantic_error(int line, const char *message) {
    fprintf(stderr, "semantic error: line %d: %s\n", line, message);
    error_count++;
}

void report_warning(int line, const char *message) {
    fprintf(stderr, "warning: line %d: %s\n", line, message);
    warning_count++;
}

bool has_errors(void) {
    return error_count > 0;
}
