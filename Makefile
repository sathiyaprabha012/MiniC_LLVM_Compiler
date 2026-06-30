# ============================================================
# MiniC-LLVM-Compiler — Top-level Makefile
# Pipeline: Flex -> Bison -> GCC -> (LLVM tools invoked at runtime)
# ============================================================

CC       := gcc
FLEX     := flex
BISON    := bison

CFLAGS   := -std=c11 -Wall -Wextra -g -Iinclude
LDFLAGS  :=

SRC_DIR     := .
BUILD_DIR   := build
OBJ_DIR     := $(BUILD_DIR)/obj
BIN_DIR     := bin
TARGET      := $(BIN_DIR)/minicc

# --- Generated parser/lexer sources ---
LEXER_L     := lexer/lexer.l
PARSER_Y    := parser/parser.y

LEXER_C     := lexer/lex.yy.c
PARSER_C    := parser/parser.tab.c
PARSER_H    := parser/parser.tab.h

# --- Hand-written C sources across all modules ---
# (Each module's directory is added here as it's implemented; empty dirs are skipped safely.)
COMMON_SRCS    := $(wildcard common/*.c)
AST_SRCS       := $(wildcard ast/*.c)
SEMANTIC_SRCS  := $(wildcard semantic/*.c)
SYMTAB_SRCS    := $(wildcard symtab/*.c)
OPTIMIZER_SRCS := $(wildcard optimizer/*.c)
IR_SRCS        := $(wildcard ir/*.c)
LLVM_SRCS      := $(wildcard llvm/*.c)
DRIVER_SRCS    := $(wildcard driver/*.c)

GENERATED_SRCS := $(LEXER_C) $(PARSER_C)

ALL_SRCS := $(GENERATED_SRCS) $(COMMON_SRCS) $(AST_SRCS) $(SEMANTIC_SRCS) \
            $(SYMTAB_SRCS) $(OPTIMIZER_SRCS) $(IR_SRCS) $(LLVM_SRCS) $(DRIVER_SRCS)

# Map every source file to an object file path under build/obj/,
# mirroring its source subdirectory (e.g. ast/ast.c -> build/obj/ast/ast.c.o)
OBJS := $(patsubst %.c,$(OBJ_DIR)/%.o,$(ALL_SRCS))

.PHONY: all clean distclean test dirs

all: dirs $(TARGET)

dirs:
	@mkdir -p $(OBJ_DIR) $(BIN_DIR)

# --- Generate lexer from Flex spec ---
$(LEXER_C): $(LEXER_L) $(PARSER_H)
	$(FLEX) -o $(LEXER_C) $(LEXER_L)

# --- Generate parser from Bison spec (also emits the token header) ---
$(PARSER_C) $(PARSER_H): $(PARSER_Y)
	$(BISON) -d -o $(PARSER_C) $(PARSER_Y)

# --- Generic compile rule: build/obj/<path>.o from <path>.c ---
$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# --- Link final binary ---
$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)
	@echo "Build complete: $(TARGET)"

# --- Run all example programs through the compiler (real behavior added in Module 13) ---
test: all
	@echo "Running valid examples..."
	@for f in examples/valid/*.mc; do \
		echo "--- $$f ---"; \
		$(TARGET) $$f || echo "FAILED: $$f"; \
	done
	@echo "Running invalid examples (errors expected)..."
	@for f in examples/invalid/*.mc; do \
		echo "--- $$f ---"; \
		$(TARGET) $$f; \
	done

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
	rm -f tokens.txt ast.txt symbol_table.txt tac.txt optimized_tac.txt output.ll

distclean: clean
	rm -f $(LEXER_C) $(PARSER_C) $(PARSER_H)
