%{
#include "parser.tab.h"   /* gerado pelo Bison; contém os tokens */
#include <string.h>
#include <stdlib.h>
%}

/* Não precisamos de yywrap – indica ao flex que não há múltiplos arquivos */
%option noyywrap

%%

"mostrar"           { return MOSTRAR; }

\"([^\"\\]|\\.)*\"  {
                        /* Captura string entre aspas duplas.
                           Remove as aspas e passa o conteúdo para o parser. */
                        yytext[yyleng - 1] = '\0';        /* apaga " final */
                        yylval.str = strdup(yytext + 1);  /* pula " inicial */
                        return STRING;
                    }

[ \t\r\n]+          { /* ignora espaços e quebras de linha */ }

";"                 { return PONTO_VIRGULA; }

.                   {
                        fprintf(stderr, "Caractere desconhecido: '%s'\n", yytext);
                    }

%%
