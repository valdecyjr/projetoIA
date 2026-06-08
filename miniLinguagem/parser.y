%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ast.h"

void yyerror(const char *msg);
int  yylex(void);

/* ================================================================
   TABELA DE SÍMBOLOS
   ================================================================ */
#define MAX_VARS 256

typedef enum { T_NUM, T_CAR, T_FRASES } VarTipo;

typedef struct {
    char    nome[64];
    VarTipo tipo;
    double  num;
    char    car;
    char   *str;
} Variavel;

static Variavel tabela[MAX_VARS];
static int      num_vars = 0;

static int buscar_var(const char *nome) {
    for (int i = 0; i < num_vars; i++)
        if (strcmp(tabela[i].nome, nome) == 0) return i;
    return -1;
}

static int criar_var(const char *nome, VarTipo tipo) {
    int idx = buscar_var(nome);
    if (idx != -1) { tabela[idx].tipo = tipo; return idx; }
    if (num_vars >= MAX_VARS) { fprintf(stderr,"Limite de variáveis!\n"); exit(1); }
    strncpy(tabela[num_vars].nome, nome, 63);
    tabela[num_vars].tipo = tipo;
    tabela[num_vars].str  = NULL;
    return num_vars++;
}

/* ================================================================
   VALOR em tempo de execução
   ================================================================ */
typedef enum { VAL_NUM, VAL_STR, VAL_CAR } ValTipo;

typedef struct {
    ValTipo tipo;
    double  num;
    char   *str;
    char    car;
} Valor;

static Valor mk_num(double n) { Valor v; v.tipo=VAL_NUM; v.num=n; v.str=NULL; v.car=0; return v; }
static Valor mk_car(char c)   { Valor v; v.tipo=VAL_CAR; v.car=c; v.str=NULL; v.num=0; return v; }
static Valor mk_str(char *s)  {
    Valor v; v.tipo=VAL_STR; v.num=0; v.car=0;
    v.str = s ? strdup(s) : strdup("");
    return v;
}

static void liberar_valor(Valor v) { if (v.tipo==VAL_STR && v.str) free(v.str); }

static double val_num(Valor v) {
    if (v.tipo==VAL_NUM) return v.num;
    if (v.tipo==VAL_CAR) return (double)(unsigned char)v.car;
    if (v.str) return atof(v.str);
    return 0;
}

static void imprimir_valor(Valor v) {
    if (v.tipo==VAL_NUM) {
        if (v.num == (long long)v.num) printf("%lld", (long long)v.num);
        else printf("%g", v.num);
    } else if (v.tipo==VAL_STR) {
        printf("%s", v.str ? v.str : "");
    } else {
        printf("%c", v.car);
    }
}

/* ================================================================
   ALOCADOR DE NÓS DA AST
   ================================================================ */
static No *novo_no(NoTipo tipo) {
    No *n = calloc(1, sizeof(No));
    n->tipo = tipo;
    return n;
}

static void liberar_no(No *no) {
    if (!no) return;
    liberar_no(no->filho[0]);
    liberar_no(no->filho[1]);
    liberar_no(no->filho[2]);
    liberar_no(no->prox);
    if (no->str) free(no->str);
    free(no);
}

/* ================================================================
   EXECUTOR DA AST
   ================================================================ */
static Valor executar(No *no);

static Valor executar_bloco(No *no) {
    Valor v = mk_num(0);
    while (no) {
        liberar_valor(v);
        v = executar(no);
        no = no->prox;
    }
    return v;
}

static Valor executar(No *no) {
    if (!no) return mk_num(0);

    switch (no->tipo) {

    /* Literais */
    case NO_NUM:  return mk_num(no->num);
    case NO_STR:  return mk_str(no->str);
    case NO_CAR:  return mk_car(no->car);
    case NO_VAZIO: return mk_num(0);

    /* Leitura de variável */
    case NO_IDENT: {
        int idx = buscar_var(no->str);
        if (idx == -1) { fprintf(stderr, "Variável '%s' não declarada.\n", no->str); return mk_num(0); }
        switch (tabela[idx].tipo) {
            case T_NUM:    return mk_num(tabela[idx].num);
            case T_CAR:    return mk_car(tabela[idx].car);
            case T_FRASES: return mk_str(tabela[idx].str ? tabela[idx].str : "");
        }
        return mk_num(0);
    }

    /* Negação unária */
    case NO_NEG: {
        Valor a = executar(no->filho[0]);
        double r = -val_num(a);
        liberar_valor(a);
        return mk_num(r);
    }

    /* Soma (também concatena strings) */
    case NO_SOMA: {
        Valor a = executar(no->filho[0]);
        Valor b = executar(no->filho[1]);
        if (a.tipo == VAL_STR || b.tipo == VAL_STR) {
            char sa[4096] = "", sb[4096] = "", buf[8192];
            if      (a.tipo == VAL_STR) strncpy(sa, a.str ? a.str : "", 4095);
            else if (a.tipo == VAL_NUM) { if (a.num==(long long)a.num) snprintf(sa,4096,"%lld",(long long)a.num); else snprintf(sa,4096,"%g",a.num); }
            else    snprintf(sa, 4096, "%c", a.car);
            if      (b.tipo == VAL_STR) strncpy(sb, b.str ? b.str : "", 4095);
            else if (b.tipo == VAL_NUM) { if (b.num==(long long)b.num) snprintf(sb,4096,"%lld",(long long)b.num); else snprintf(sb,4096,"%g",b.num); }
            else    snprintf(sb, 4096, "%c", b.car);
            snprintf(buf, 8192, "%s%s", sa, sb);
            liberar_valor(a); liberar_valor(b);
            return mk_str(buf);
        }
        double r = val_num(a) + val_num(b);
        liberar_valor(a); liberar_valor(b);
        return mk_num(r);
    }

    case NO_SUB:  { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)-val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_MULT: { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)*val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_DIV:  {
        Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]);
        double db=val_num(b);
        if (db==0) { fprintf(stderr,"Divisão por zero!\n"); liberar_valor(a); liberar_valor(b); return mk_num(0); }
        double r=val_num(a)/db; liberar_valor(a); liberar_valor(b); return mk_num(r);
    }
    case NO_MOD: { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=fmod(val_num(a),val_num(b)); liberar_valor(a); liberar_valor(b); return mk_num(r); }

    /* Comparações */
    case NO_EQ: {
        Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); int r;
        if (a.tipo==VAL_STR && b.tipo==VAL_STR) r=strcmp(a.str?a.str:"", b.str?b.str:"")==0;
        else r=val_num(a)==val_num(b);
        liberar_valor(a); liberar_valor(b); return mk_num(r);
    }
    case NO_NEQ: {
        Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); int r;
        if (a.tipo==VAL_STR && b.tipo==VAL_STR) r=strcmp(a.str?a.str:"", b.str?b.str:"")!=0;
        else r=val_num(a)!=val_num(b);
        liberar_valor(a); liberar_valor(b); return mk_num(r);
    }
    case NO_GT:  { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)> val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_LT:  { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)< val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_GEQ: { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)>=val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_LEQ: { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)<=val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }

    /* Lógica */
    case NO_AND: { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)&&val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_OR:  { Valor a=executar(no->filho[0]); Valor b=executar(no->filho[1]); double r=val_num(a)||val_num(b); liberar_valor(a); liberar_valor(b); return mk_num(r); }
    case NO_NOT: { Valor a=executar(no->filho[0]); double r=!val_num(a); liberar_valor(a); return mk_num(r); }

    /* mostrar */
    case NO_MOSTRAR: {
        Valor v = executar(no->filho[0]);
        imprimir_valor(v);
        printf("\n");
        liberar_valor(v);
        return mk_num(0);
    }

    /* Declarações */
    case NO_DECL_NUM: {
        int idx = criar_var(no->str, T_NUM);
        Valor v = executar(no->filho[0]);
        tabela[idx].num = val_num(v);
        liberar_valor(v);
        return mk_num(0);
    }
    case NO_DECL_CAR: {
        int idx = criar_var(no->str, T_CAR);
        Valor v = executar(no->filho[0]);
        tabela[idx].car = (v.tipo==VAL_CAR) ? v.car : (char)(int)val_num(v);
        liberar_valor(v);
        return mk_num(0);
    }
    case NO_DECL_FRASES: {
        int idx = criar_var(no->str, T_FRASES);
        Valor v = executar(no->filho[0]);
        if (tabela[idx].str) free(tabela[idx].str);
        /* transfere ownership da string alocada por mk_str */
        tabela[idx].str = (v.tipo==VAL_STR && v.str) ? v.str : strdup("");
        if (v.tipo != VAL_STR) liberar_valor(v);
        return mk_num(0);
    }

    /* Atribuição */
    case NO_ATRIB: {
        int idx = buscar_var(no->str);
        if (idx == -1) { fprintf(stderr, "Variável '%s' não declarada.\n", no->str); return mk_num(0); }
        Valor v = executar(no->filho[0]);
        switch (tabela[idx].tipo) {
            case T_NUM:
                tabela[idx].num = val_num(v);
                liberar_valor(v);
                break;
            case T_CAR:
                tabela[idx].car = (v.tipo==VAL_CAR) ? v.car : (char)(int)val_num(v);
                liberar_valor(v);
                break;
            case T_FRASES:
                if (tabela[idx].str) free(tabela[idx].str);
                tabela[idx].str = (v.tipo==VAL_STR && v.str) ? v.str : strdup("");
                if (v.tipo != VAL_STR) liberar_valor(v);
                break;
        }
        return mk_num(0);
    }

    /* se / senao */
    case NO_SE: {
        Valor cond = executar(no->filho[0]);
        int verdade = (int)val_num(cond);
        liberar_valor(cond);
        if (verdade)
            return executar_bloco(no->filho[1]);
        else if (no->filho[2])
            return executar_bloco(no->filho[2]);
        return mk_num(0);
    }

    /* enquanto */
    case NO_ENQUANTO: {
        Valor r = mk_num(0);
        for (;;) {
            Valor cond = executar(no->filho[0]);
            int verdade = (int)val_num(cond);
            liberar_valor(cond);
            if (!verdade) break;
            liberar_valor(r);
            r = executar_bloco(no->filho[1]);
        }
        return r;
    }

    default:
        return mk_num(0);
    }
}

%}

/* ----------------------------------------------------------------
   União semântica
   ---------------------------------------------------------------- */
%union {
    double  dval;
    char    cval;
    char   *str;
    No     *no;
}

/* ----------------------------------------------------------------
   Tokens
   ---------------------------------------------------------------- */
%token MOSTRAR
%token TIPO_NUM TIPO_CAR TIPO_FRASES
%token SE SENAO ENQUANTO
%token PONTO_VIRGULA ATRIB
%token ABRE_PAR FECHA_PAR ABRE_CHAVE FECHA_CHAVE
%token MAIS MENOS MULT DIV MOD
%token EQ NEQ GT LT GEQ LEQ AND OR NOT

%token <dval> NUM_INT NUM_FLOAT
%token <cval> CHAR_LIT
%token <str>  STRING IDENT

%type <no> lista_cmds bloco comando expr

/* Precedência (menor → maior) */
%left OR
%left AND
%right NOT
%left EQ NEQ
%left LT GT LEQ GEQ
%left MAIS MENOS
%left MULT DIV MOD
%right UMINUS

%%

/* ================================================================
   GRAMÁTICA
   ================================================================ */

programa
    : lista_cmds  { executar_bloco($1); liberar_no($1); }
    ;

lista_cmds
    : /* vazio */          { $$ = NULL; }
    | lista_cmds comando   {
        if ($1 == NULL) {
            $$ = $2;
        } else {
            No *ult = $1;
            while (ult->prox) ult = ult->prox;
            ult->prox = $2;
            $$ = $1;
        }
    }
    ;

bloco
    : ABRE_CHAVE lista_cmds FECHA_CHAVE  { $$ = $2; }
    ;

comando
    : MOSTRAR expr PONTO_VIRGULA
        { No *n=novo_no(NO_MOSTRAR); n->filho[0]=$2; $$=n; }

    | TIPO_NUM IDENT ATRIB expr PONTO_VIRGULA
        { No *n=novo_no(NO_DECL_NUM); n->str=$2; n->filho[0]=$4; $$=n; }

    | TIPO_CAR IDENT ATRIB expr PONTO_VIRGULA
        { No *n=novo_no(NO_DECL_CAR); n->str=$2; n->filho[0]=$4; $$=n; }

    | TIPO_FRASES IDENT ATRIB expr PONTO_VIRGULA
        { No *n=novo_no(NO_DECL_FRASES); n->str=$2; n->filho[0]=$4; $$=n; }

    | IDENT ATRIB expr PONTO_VIRGULA
        { No *n=novo_no(NO_ATRIB); n->str=$1; n->filho[0]=$3; $$=n; }

    | SE ABRE_PAR expr FECHA_PAR bloco
        { No *n=novo_no(NO_SE); n->filho[0]=$3; n->filho[1]=$5; n->filho[2]=NULL; $$=n; }

    | SE ABRE_PAR expr FECHA_PAR bloco SENAO bloco
        { No *n=novo_no(NO_SE); n->filho[0]=$3; n->filho[1]=$5; n->filho[2]=$7; $$=n; }

    | ENQUANTO ABRE_PAR expr FECHA_PAR bloco
        { No *n=novo_no(NO_ENQUANTO); n->filho[0]=$3; n->filho[1]=$5; $$=n; }
    ;

expr
    : NUM_INT   { No *n=novo_no(NO_NUM); n->num=$1; $$=n; }
    | NUM_FLOAT { No *n=novo_no(NO_NUM); n->num=$1; $$=n; }
    | CHAR_LIT  { No *n=novo_no(NO_CAR); n->car=$1; $$=n; }
    | STRING    { No *n=novo_no(NO_STR); n->str=$1; $$=n; }
    | IDENT     { No *n=novo_no(NO_IDENT); n->str=$1; $$=n; }

    | expr MAIS  expr  { No *n=novo_no(NO_SOMA); n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr MENOS expr  { No *n=novo_no(NO_SUB);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr MULT  expr  { No *n=novo_no(NO_MULT); n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr DIV   expr  { No *n=novo_no(NO_DIV);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr MOD   expr  { No *n=novo_no(NO_MOD);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | MENOS expr %prec UMINUS { No *n=novo_no(NO_NEG); n->filho[0]=$2; $$=n; }

    | expr EQ  expr  { No *n=novo_no(NO_EQ);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr NEQ expr  { No *n=novo_no(NO_NEQ); n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr GT  expr  { No *n=novo_no(NO_GT);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr LT  expr  { No *n=novo_no(NO_LT);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr GEQ expr  { No *n=novo_no(NO_GEQ); n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr LEQ expr  { No *n=novo_no(NO_LEQ); n->filho[0]=$1; n->filho[1]=$3; $$=n; }

    | expr AND expr  { No *n=novo_no(NO_AND); n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | expr OR  expr  { No *n=novo_no(NO_OR);  n->filho[0]=$1; n->filho[1]=$3; $$=n; }
    | NOT expr       { No *n=novo_no(NO_NOT); n->filho[0]=$2; $$=n; }

    | ABRE_PAR expr FECHA_PAR { $$ = $2; }
    ;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "Erro de sintaxe: %s\n", msg);
}

int main(int argc, char *argv[]) {
    if (argc < 2) { fprintf(stderr, "Uso: %s <arquivo>\n", argv[0]); return 1; }
    extern FILE *yyin;
    yyin = fopen(argv[1], "r");
    if (!yyin) { perror("Erro ao abrir arquivo"); return 1; }
    yyparse();
    fclose(yyin);
    for (int i = 0; i < num_vars; i++)
        if (tabela[i].tipo == T_FRASES && tabela[i].str)
            free(tabela[i].str);
    return 0;
}
