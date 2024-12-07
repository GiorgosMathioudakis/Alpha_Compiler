#ifndef INTERMEDIATECODE_HPP
#define INTERMEDIATECODE_HPP

#include <variant>
#include <cassert>
#include "symbol_Table.hpp"
using namespace std;

typedef enum {
    IOP_ASSIGN , 
    IOP_ADD ,
    IOP_SUB ,
    IOP_MUL ,
    IOP_DIV ,
    IOP_MOD ,
    IOP_UMINUS ,
    IOP_AND ,
    IOP_OR ,
    IOP_NOT ,
    IOP_IF_EQ ,
    IOP_IF_NOTEQ ,
    IOP_IF_LESSEQ ,
    IOP_IF_GREATEREQ ,
    IOP_IF_LESS ,
    IOP_IF_GREATER ,
    IOP_CALL , 
    IOP_PARAM ,
    IOP_RET ,
    IOP_GETRETVAL , 
    IOP_FUNCSTART ,
    IOP_FUNCEND ,
    IOP_TABLECREATE , 
    IOP_TABLEGETELEM ,
    IOP_TABLESETELEM ,
    IOP_JUMP ,
    IOP_NOP,
} Opcode;

typedef enum{
    VAR_E,
    TABLEITEM_E,
    PROGRAMFUNC_E,
    LIBRARYFUNC_E,
    ARITHMEXPR_E,
    BOOLEXPR_E,
    ASSIGNEXPR_E,
    NEWTABLE_E,
    CONSTNUM_E,
    CONSTBOOL_E,
    CONSTSTRING_E,
    NIL_E,
} Expr_T;

typedef struct Expr{
    Expr_T type;
    Symbol *sym;
    variant<string, double, bool, int> value;
    Expr* index;
    Expr* next;
} Expr;

typedef struct Quad{
    Opcode op;
    Expr* result;
    Expr* arg1;
    Expr* arg2;
    unsigned int label;
    unsigned int line;
    unsigned int taddress;
} Quad;

typedef struct Call{
    list<Expr*> eList;
    unsigned char method ; 
    string name;
} Call; 

/*external variables*/
extern unsigned int programVarOffset;
extern unsigned int functionLocalOffset;
extern unsigned int formalArgOffset;
extern unsigned int scopeSpaceCounter;
extern unsigned int tempCounter;
extern unsigned int scope;
extern Symbol_Table symtable;
extern vector<Quad*> Quads;
extern int yylineno;

int mergelist (int l1, int l2);

unsigned int currscope();

string newTempName();

void resetTemp();

Symbol* newTemp();

void emit(Opcode op, Expr* arg1, Expr* arg2, Expr* result, unsigned int label, unsigned int line);

scopespace_t currscopespace();

unsigned int currscopeoffset();

void inccurrscopeoffset();

void enterscopespace();

std::list<Expr*> ReverseElist(Expr *expr);

void exitscopespace();

void resetformalargsoffset();

void resetfunctionlocalsoffset();

void restorecurrscopeoffset(unsigned int offset);

unsigned int nextquadlabel();

void patchlabel(unsigned int quadNo, unsigned int label);

Expr* lvalue_expr(Symbol* sym);

Expr* newExpr(Expr_T type);

bool isTempSymbol(Symbol* sym);

Expr* newExpr_conststring(string s);

Expr* newExpr_bool(bool b);

Expr* newExpr_constnum(double d);

Expr* newExpr_constnum(int i);

Expr* emit_iftableitem(Expr* expr,unsigned int lineno);

bool check_arrith(Expr* expr , const string context);

unsigned int istempname(string s);

unsigned int istempexpr(Expr* expr);

Expr_T const_check(Expr *expr1, Expr *expr2);

Expr* newexpr_constbool(unsigned int b);

bool isValidArithmeticOperation(Expr* e1, Expr* e2);

bool check_arith(Expr* expr);

int newlist (int i);

Expr* make_call(Expr* lv ,std::list<Expr*> reversed_elist,unsigned int line);

void print_Quads();

Expr* member_item(Expr* lv , string name);

Expr* change_value(Expr* expr , std::variant<std::string, double, bool, int> value);

Expr* change_type(Expr* expr ,Expr_T type);

int makelist (int i);

void patchlist (int list, int label);

string opcodeToString(Opcode op);

string exprValueToString(Expr* expr);


#endif