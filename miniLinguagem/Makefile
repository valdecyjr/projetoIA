# ---------------------------------------------------------------
# Makefile – Mini Linguagem com Flex + Bison
# Funciona em Linux (gcc) e Windows (MinGW/MSYS2 com win_flex/win_bison)
# ---------------------------------------------------------------

# ---------- Detecta o sistema operacional ----------
ifeq ($(OS),Windows_NT)
    # Windows: usa win_flex e win_bison (instalados via MSYS2/Chocolatey)
    FLEX    = win_flex
    BISON   = win_bison
    CC      = gcc
    TARGET  = interpretador.exe
    RM      = del /Q
else
    # Linux / macOS
    FLEX    = flex
    BISON   = bison
    CC      = gcc
    TARGET  = interpretador
    RM      = rm -f
endif

# ---------- Flags ----------
CFLAGS = -Wall -Wextra -g

# ---------- Arquivos gerados ----------
LEX_C    = lex.yy.c
PARSER_C = parser.tab.c
PARSER_H = parser.tab.h

# ---------- Regra principal ----------
all: $(TARGET)

$(TARGET): $(LEX_C) $(PARSER_C)
	$(CC) $(CFLAGS) -o $@ $(PARSER_C) $(LEX_C) -lfl 2>/dev/null || \
	$(CC) $(CFLAGS) -o $@ $(PARSER_C) $(LEX_C)
# Nota: -lfl vincula a biblioteca do flex no Linux.
# No Windows com MinGW o flag pode não ser necessário; o || tenta sem ele.

# Gera o parser a partir do arquivo Bison (-d cria o .h com os tokens)
$(PARSER_C) $(PARSER_H): parser.y
	$(BISON) -d parser.y

# Gera o lexer a partir do arquivo Flex
$(LEX_C): lexer.l $(PARSER_H)
	$(FLEX) lexer.l

# ---------- Limpeza ----------
clean:
	$(RM) $(LEX_C) $(PARSER_C) $(PARSER_H) $(TARGET)

# ---------- Execução de exemplo ----------
run: $(TARGET) exemplo.minha
	./$(TARGET) exemplo.minha

# ---------- Cria um arquivo de exemplo ----------
exemplo:
	@echo mostrar "Olá, Mundo!" ;  > exemplo.minha
	@echo mostrar "Segunda linha!" ; >> exemplo.minha
	@echo Arquivo exemplo.minha criado!

.PHONY: all clean run exemplo
