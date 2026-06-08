%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Protótipos exigidos pelo Bison */
void yyerror(const char *msg);
int  yylex(void);
%}

/* Define o tipo semântico: strings vindas do lexer */
%union {
    char *str;
}

/* Declaração dos tokens */
%token MOSTRAR PONTO_VIRGULA
%token <str> STRING

%%

/* ---------------------------------------------------------------
   Gramática
   programa  : lista de comandos (zero ou mais)
   comando   : mostrar "algum texto" ;
   --------------------------------------------------------------- */

programa
    : /* vazio – programa pode ser vazio */
    | programa comando
    ;

comando
    : MOSTRAR STRING PONTO_VIRGULA
        {
            printf("%s\n", $2);
            free($2);   /* libera a string alocada pelo lexer */
        }
    ;

%%

/* ---------------------------------------------------------------
   Tratamento de erros sintáticos
   --------------------------------------------------------------- */
void yyerror(const char *msg) {
    fprintf(stderr, "Erro de sintaxe: %s\n", msg);
}

/* ---------------------------------------------------------------
   Ponto de entrada
   --------------------------------------------------------------- */
int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo.minha>\n", argv[0]);
        return 1;
    }

    extern FILE *yyin;          /* arquivo de entrada do flex */
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Erro ao abrir arquivo");
        return 1;
    }

    yyparse();                  /* inicia a análise */
    fclose(yyin);
    return 0;
}
