ifeq ($(OS),Windows_NT)
    FLEX    = win_flex
    BISON   = win_bison
    CC      = gcc
    TARGET  = interpretador.exe
    RM      = del /Q
else
    FLEX    = flex
    BISON   = bison
    CC      = gcc
    TARGET  = interpretador
    RM      = rm -f
endif

CFLAGS   = -Wall -Wextra -g
LEX_C    = lex.yy.c
PARSER_C = parser.tab.c
PARSER_H = parser.tab.h

all: $(TARGET)

$(TARGET): $(LEX_C) $(PARSER_C)
	$(CC) $(CFLAGS) -o $@ $(PARSER_C) $(LEX_C) -lm -lfl 2>/dev/null || \
	$(CC) $(CFLAGS) -o $@ $(PARSER_C) $(LEX_C) -lm

$(PARSER_C) $(PARSER_H): parser.y
	$(BISON) -d parser.y

$(LEX_C): lexer.l $(PARSER_H)
	$(FLEX) lexer.l

clean:
	$(RM) $(LEX_C) $(PARSER_C) $(PARSER_H) $(TARGET)

run: $(TARGET) exemplo.minha
	./$(TARGET) exemplo.minha

.PHONY: all clean run
