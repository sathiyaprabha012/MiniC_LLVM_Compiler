/* ============================================================
   MiniC-LLVM-Compiler — AST implementation
   ast/ast.c
   ============================================================ */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

#define INITIAL_CHILD_CAPACITY 4

/* ---- Node type name table, used by print_ast() ---- */
static const char *node_type_to_string(NodeType type) {
    switch (type) {
        case NODE_PROGRAM:       return "PROGRAM";
        case NODE_FUNC_DECL:     return "FUNC_DECL";
        case NODE_PARAM_LIST:    return "PARAM_LIST";
        case NODE_PARAM:         return "PARAM";
        case NODE_BLOCK:         return "BLOCK";
        case NODE_VAR_DECL:      return "VAR_DECL";
        case NODE_ARRAY_DECL:    return "ARRAY_DECL";
        case NODE_IF:            return "IF";
        case NODE_WHILE:         return "WHILE";
        case NODE_FOR:           return "FOR";
        case NODE_RETURN:        return "RETURN";
        case NODE_EXPR_STMT:     return "EXPR_STMT";
        case NODE_ASSIGN:        return "ASSIGN";
        case NODE_BINOP:         return "BINOP";
        case NODE_UNARYOP:       return "UNARYOP";
        case NODE_LOGICAL:       return "LOGICAL";
        case NODE_COMPARE:       return "COMPARE";
        case NODE_FUNC_CALL:     return "FUNC_CALL";
        case NODE_ARRAY_ACCESS:  return "ARRAY_ACCESS";
        case NODE_IDENTIFIER:    return "IDENTIFIER";
        case NODE_INT_LITERAL:   return "INT_LITERAL";
        case NODE_FLOAT_LITERAL: return "FLOAT_LITERAL";
        case NODE_CHAR_LITERAL:  return "CHAR_LITERAL";
        case NODE_BOOL_LITERAL:  return "BOOL_LITERAL";
        default:                 return "UNKNOWN_NODE";
    }
}

/* ---- Node creation ---- */

ASTNode *create_node(NodeType type, int line, const char *str_value) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    if (node == NULL) {
        fprintf(stderr, "fatal: out of memory in create_node()\n");
        exit(EXIT_FAILURE);
    }

    node->type = type;
    node->line = line;
    node->data_type = TYPE_UNKNOWN;

    node->children = (ASTNode **)malloc(sizeof(ASTNode *) * INITIAL_CHILD_CAPACITY);
    if (node->children == NULL) {
        fprintf(stderr, "fatal: out of memory in create_node() (children array)\n");
        exit(EXIT_FAILURE);
    }
    node->num_children = 0;
    node->capacity = INITIAL_CHILD_CAPACITY;

    if (str_value != NULL) {
        node->str_value = (char *)malloc(strlen(str_value) + 1);
        if (node->str_value == NULL) {
            fprintf(stderr, "fatal: out of memory in create_node() (str_value)\n");
            exit(EXIT_FAILURE);
        }
        strcpy(node->str_value, str_value);
    } else {
        node->str_value = NULL;
    }

    node->int_value = 0;
    node->float_value = 0.0f;
    node->char_value = '\0';

    return node;
}

/* ---- Child management ---- */

void add_child(ASTNode *parent, ASTNode *child) {
    if (parent == NULL || child == NULL) {
        return; /* silently ignore NULL child — lets optional grammar productions pass through safely */
    }

    if (parent->num_children >= parent->capacity) {
        int new_capacity = parent->capacity * 2;
        ASTNode **new_children = (ASTNode **)realloc(parent->children, sizeof(ASTNode *) * new_capacity);
        if (new_children == NULL) {
            fprintf(stderr, "fatal: out of memory in add_child() (realloc)\n");
            exit(EXIT_FAILURE);
        }
        parent->children = new_children;
        parent->capacity = new_capacity;
    }

    parent->children[parent->num_children] = child;
    parent->num_children++;
}

/* ---- Literal leaf constructors ---- */

ASTNode *create_int_literal(int value, int line) {
    ASTNode *node = create_node(NODE_INT_LITERAL, line, NULL);
    node->data_type = TYPE_INT;
    node->int_value = value;
    return node;
}

ASTNode *create_float_literal(float value, int line) {
    ASTNode *node = create_node(NODE_FLOAT_LITERAL, line, NULL);
    node->data_type = TYPE_FLOAT;
    node->float_value = value;
    return node;
}

ASTNode *create_char_literal(char value, int line) {
    ASTNode *node = create_node(NODE_CHAR_LITERAL, line, NULL);
    node->data_type = TYPE_CHAR;
    node->char_value = value;
    return node;
}

ASTNode *create_bool_literal(int value, int line) {
    ASTNode *node = create_node(NODE_BOOL_LITERAL, line, NULL);
    node->data_type = TYPE_BOOL;
    node->int_value = value; /* 0 = false, 1 = true */
    return node;
}

ASTNode *create_identifier(const char *name, int line) {
    ASTNode *node = create_node(NODE_IDENTIFIER, line, name);
    node->data_type = TYPE_UNKNOWN; /* resolved later during semantic analysis */
    return node;
}

/* ---- Printing (produces ast.txt) ---- */

static void print_indent(int depth, FILE *out) {
    for (int i = 0; i < depth; i++) {
        fprintf(out, "  "); /* 2 spaces per depth level */
    }
}

void print_ast(ASTNode *node, int depth, FILE *out) {
    if (node == NULL) {
        return;
    }

    print_indent(depth, out);
    fprintf(out, "%s", node_type_to_string(node->type));

    if (node->str_value != NULL) {
        fprintf(out, " '%s'", node->str_value);
    }

    switch (node->type) {
        case NODE_INT_LITERAL:
            fprintf(out, " = %d", node->int_value);
            break;
        case NODE_FLOAT_LITERAL:
            fprintf(out, " = %f", node->float_value);
            break;
        case NODE_CHAR_LITERAL:
            fprintf(out, " = '%c'", node->char_value);
            break;
        case NODE_BOOL_LITERAL:
            fprintf(out, " = %s", node->int_value ? "true" : "false");
            break;
        default:
            break;
    }

    if (node->data_type != TYPE_UNKNOWN) {
        fprintf(out, " : %s", data_type_to_string(node->data_type));
    }

    fprintf(out, " (line %d)\n", node->line);

    for (int i = 0; i < node->num_children; i++) {
        print_ast(node->children[i], depth + 1, out);
    }
}

/* ---- Freeing ---- */

void free_ast(ASTNode *node) {
    if (node == NULL) {
        return;
    }

    for (int i = 0; i < node->num_children; i++) {
        free_ast(node->children[i]);
    }

    free(node->children);

    if (node->str_value != NULL) {
        free(node->str_value);
    }

    free(node);
}
