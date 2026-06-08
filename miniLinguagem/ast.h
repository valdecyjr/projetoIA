#ifndef AST_H
#define AST_H

typedef enum {
    NO_NUM, NO_STR, NO_CAR,
    NO_IDENT,
    NO_SOMA, NO_SUB, NO_MULT, NO_DIV, NO_MOD, NO_NEG,
    NO_EQ, NO_NEQ, NO_GT, NO_LT, NO_GEQ, NO_LEQ,
    NO_AND, NO_OR, NO_NOT,
    NO_MOSTRAR,
    NO_DECL_NUM, NO_DECL_CAR, NO_DECL_FRASES,
    NO_ATRIB,
    NO_SE,
    NO_ENQUANTO,
    NO_BLOCO,
    NO_VAZIO
} NoTipo;

typedef struct No {
    NoTipo    tipo;
    double    num;
    char     *str;
    char      car;
    struct No *filho[3];
    struct No *prox;
} No;

#endif
