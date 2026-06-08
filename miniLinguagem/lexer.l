%{
#include "ast.h"
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%option noyywrap

%%

"mostrar"           { return MOSTRAR; }
"num"               { return TIPO_NUM; }
"car"               { return TIPO_CAR; }
"frases"            { return TIPO_FRASES; }
"se"                { return SE; }
"senao"             { return SENAO; }
"enquanto"          { return ENQUANTO; }

"=="                { return EQ; }
"!="                { return NEQ; }
">="                { return GEQ; }
"<="                { return LEQ; }
">"                 { return GT; }
"<"                 { return LT; }
"&&"                { return AND; }
"||"                { return OR; }
"!"                 { return NOT; }

"="                 { return ATRIB; }
"+"                 { return MAIS; }
"-"                 { return MENOS; }
"*"                 { return MULT; }
"/"                 { return DIV; }
"%"                 { return MOD; }

";"                 { return PONTO_VIRGULA; }
"("                 { return ABRE_PAR; }
")"                 { return FECHA_PAR; }
"{"                 { return ABRE_CHAVE; }
"}"                 { return FECHA_CHAVE; }

[0-9]+\.[0-9]+      { yylval.dval = atof(yytext);            return NUM_FLOAT; }
[0-9]+              { yylval.dval = (double)atoi(yytext);    return NUM_INT; }

\'[^\']\' {
                        yylval.cval = yytext[1];
                        return CHAR_LIT;
                    }

\"([^\"\\]|\\.)*\"  {
                        yytext[yyleng - 1] = '\0';
                        yylval.str = strdup(yytext + 1);
                        return STRING;
                    }

[a-zA-Z_][a-zA-Z0-9_]*  {
                        yylval.str = strdup(yytext);
                        return IDENT;
                    }

[ \t\r\n]+          { /* ignora whitespace */ }

.                   { fprintf(stderr, "Caractere desconhecido: '%s'\n", yytext); }

%%
