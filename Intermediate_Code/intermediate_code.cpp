#include "intermediate_code.hpp"
unsigned quadsNo=0;

void emit(Opcode op, Expr* arg1, Expr* arg2, Expr* result, unsigned int label, unsigned int line){
    Quad* quad = new Quad();
    quad->op = op;
    quad->arg1 = arg1;
    quad->arg2 = arg2;
    quad->result = result;
    quad->label = label;
    quad->line = line;
    Quads.push_back(quad);
    ++quadsNo;
}

Symbol* newTemp(){
    string name = newTempName();
    Symbol* sym = symtable.lookup(name,currscope());
    symbol_T type = LOCAL_VAR;
    if(sym == NULL){
        Symbol* newsymbol = new Symbol(type,name,yylineno,currscope(),true);
        newsymbol->setOffset(currscopeoffset());
        newsymbol->setSpace(currscopespace());
        symtable.insertValue(newsymbol);
        return newsymbol;
    }else{
        return sym;
    }
}

unsigned int currscope(){
    return scope;
}

string newTempName(){
    return "_t" + to_string(tempCounter++);
}

bool isTemp(Symbol* symbol) {
    return symbol->getIdent().rfind("$", 0) == 0;
}

void resetTemp(){
    tempCounter = 0;
}

scopespace_t currscopespace(){
    if(scopeSpaceCounter == 1) return PROGRAM_VAR;
    else if(scopeSpaceCounter % 2 == 0) return FORMAL_ARG;
    else return FUNCTION_LOCAL;
}

unsigned int currscopeoffset(){
    switch(currscopespace()){
        case PROGRAM_VAR: return programVarOffset;
        case FUNCTION_LOCAL: return functionLocalOffset;
        case FORMAL_ARG: return formalArgOffset;
        default: assert(0);
    }
}

void inccurrscopeoffset(){
    switch(currscopespace()){
        case PROGRAM_VAR: ++programVarOffset; break;
        case FUNCTION_LOCAL: ++functionLocalOffset; break;
        case FORMAL_ARG: ++formalArgOffset; break;
        default: assert(0);
    }
}

void enterscopespace(){
    ++scopeSpaceCounter;
}

void exitscopespace(){
    assert(scopeSpaceCounter > 1);
    --scopeSpaceCounter;
}

void resetformalargsoffset(){
    formalArgOffset = 0;
}

void resetfunctionlocalsoffset(){
    functionLocalOffset = 0;
}

void restorecurrscopeoffset(unsigned int offset){
    switch(currscopespace()){
        case PROGRAM_VAR: programVarOffset = offset; break;
        case FUNCTION_LOCAL: functionLocalOffset = offset; break;
        case FORMAL_ARG: formalArgOffset = offset; break;
        default: assert(0);
    }
}

unsigned int nextquadlabel(){
    return quadsNo;
}

void patchlabel(unsigned int quadNo, unsigned int label){
    assert(quadNo < quadsNo);
    Quads[quadNo]->label = label;
}

Expr* lvalue_expr(Symbol* sym){
    assert(sym);
    Expr* expr = new Expr();
    expr->sym = sym;
    expr->value = sym->getIdent();
    expr->next = NULL;
    switch(sym->getType()){
        case GLOBAL_VAR: expr->type = VAR_E; break;
        case LOCAL_VAR: expr->type = VAR_E; break;
        case FORMAL_VAR: expr->type = VAR_E; break;
        case USER_FUNCTION: expr->type = PROGRAMFUNC_E; break;
        case LIBRARY_FUNCTION: expr->type = LIBRARYFUNC_E; break;
        case __ERROR__: assert(0);
        default: assert(0);
    }
    return expr;
}

Expr* newExpr(Expr_T type){
    struct Expr *expr = new Expr();
    expr->type = type;
    expr->next = NULL;
    return expr;
}

Expr* newExpr_conststring(string s){
    Expr* expr = newExpr(CONSTSTRING_E);
    expr->value = s;
    return expr;
}

Expr* newExpr_bool(bool b){
    Expr* expr = newExpr(CONSTBOOL_E);
    expr->value = b;
    return expr;
}

Expr* newExpr_constnum(double d){
    Expr* expr = newExpr(CONSTNUM_E);
    expr -> type = CONSTNUM_E;
    expr->value = d;
    return expr;
}

Expr* newExpr_constnum(int i){
    Expr* expr = newExpr(CONSTNUM_E);
    expr->value = i;
    return expr;
}

Expr* emit_iftableitem(Expr* expr,unsigned int lineno){
    if(expr->type != TABLEITEM_E){
        return expr;
    }else{
        Expr* result = newExpr(VAR_E);
        result->sym = newTemp();
        emit(
            IOP_TABLEGETELEM,
            expr,
            expr->index,
            result,
            0,
            lineno
        );
        return result;
    }
}

bool check_arrith(Expr* expr , const string context){
    if(expr->type == ARITHMEXPR_E){
       return true;
    }
    return false;
}

bool isValidArithmeticOperation(Expr* e1, Expr* e2) {
    if (e1 == NULL || e2 == NULL) return false;
    return check_arith(e1) && check_arith(e2);
}

bool check_arith(Expr* expr) {
    return expr->type == VAR_E ||
        expr->type == TABLEITEM_E ||
        expr->type == ARITHMEXPR_E ||
        expr->type == CONSTNUM_E;
}

list<Expr*> ReverseElist(Expr *expr){
    list<Expr*> temp_list = list<Expr*>();
    stack<Expr*> temp_stack = stack<Expr*>();

    while(expr){
        temp_stack.push(expr);
        expr = expr->next;
    }

    while(!temp_stack.empty()){
        temp_list.push_front(temp_stack.top());
        temp_stack.pop();
    }

    return temp_list;
}

bool isTempSymbol(Symbol* sym) {
    return sym->getIdent().rfind("$", 0) == 0;
}

Expr_T const_check(Expr *expr1, Expr *expr2){
    if (expr1->type == CONSTNUM_E && expr2->type == CONSTNUM_E) {
        return CONSTNUM_E;
    }
    return CONSTNUM_E;
}

unsigned int istempname(string s){
    return s[0] == '_';
}

unsigned int istempexpr(Expr* expr){
    return expr->sym && istempname(expr->sym->getIdent());
}

int newlist (int i){ 
    Quads[i]->label = 0; 
    return i; 
}

int mergelist (int l1, int l2) {
    if (!l1){
        return l2;
    }else{
        if (!l2){
            return l1;
        }else {
            int i = l1;
            while (Quads[i]->label){
                i = Quads[i]->label;
            }
            Quads[i]->label = l2;
            return l1;
        }
    }
}

Expr* make_call(Expr* lv ,std::list<Expr*> reversed_elist,unsigned int line){
    Expr* func = emit_iftableitem(lv,line);
    while ( !reversed_elist.empty() ){
        emit(IOP_PARAM , reversed_elist.back() , NULL , NULL , 0 , line);
        reversed_elist.pop_back();
    }
    emit(IOP_CALL , func , NULL , NULL , 0 , line);
    Expr* result = newExpr(VAR_E);
    result->sym = newTemp();
    emit(IOP_GETRETVAL , NULL , NULL , result , 0 , line);
    return result;
}

Expr* member_item(Expr* lv , string name){
    lv = emit_iftableitem(lv,0);// Emit code if r-value use of table item
    Expr* ti = newExpr(TABLEITEM_E);// Make a new expression
    ti -> sym = lv->sym;
    ti->index = newExpr_conststring(name);// Const string index
    return ti;
}

Expr* change_value(Expr* expr , std::variant<std::string, double, bool, int> value){
    expr->value = value;
    return expr;
}

Expr* change_type(Expr* expr ,Expr_T type){
    expr->type= type;
    return expr;
}

int makelist (int i){ 
    Quads[i]->label = 0; 
    return i; 
}

void patchlist (int list, int label) {
    while (list) {
        int next = Quads[list]->label;
        Quads[list]->label = label;
        list = next;
    }
}

string opcodeToString(Opcode op) {
    switch (op) {
        case IOP_ASSIGN: return "IOP_ASSIGN         ";
        case IOP_ADD: return "IOP_ADD         ";
        case IOP_SUB: return "IOP_SUB         ";
        case IOP_MUL: return "IOP_MUL         ";
        case IOP_DIV: return "IOP_DIV         ";
        case IOP_MOD: return "IOP_MOD         ";
        case IOP_UMINUS: return "IOP_UMINUS      ";
        case IOP_AND: return "IOP_AND         ";
        case IOP_OR: return "IOP_OR           ";
        case IOP_NOT: return "IOP_NOT         ";
        case IOP_IF_EQ: return "IOP_IF_EQ        "      ;
        case IOP_IF_NOTEQ: return "IOP_IF_NOTEQ    ";
        case IOP_IF_LESSEQ: return "IOP_IF_LESSEQ   ";
        case IOP_IF_GREATEREQ: return "IOP_IF_GREATEREQ ";
        case IOP_IF_LESS: return "IOP_IF_LESS     ";
        case IOP_IF_GREATER: return "IOP_IF_GREATER  ";
        case IOP_CALL: return "IOP_CALL        ";
        case IOP_PARAM: return "IOP_PARAM       ";
        case IOP_RET: return "IOP_RET         ";
        case IOP_GETRETVAL: return "IOP_GETRETVAL    ";
        case IOP_FUNCSTART: return "IOP_FUNCSTART    ";
        case IOP_FUNCEND: return "IOP_FUNCEND     ";
        case IOP_TABLECREATE: return "IOP_TABLECREATE ";
        case IOP_TABLEGETELEM: return "IOP_TABLEGETELEM";                
        case IOP_TABLESETELEM: return "IOP_TABLESETELEM";                  
        case IOP_JUMP: return "IOP_JUMP        ";
        default: return "UNKNOWN_OPCODE";
    }
}

void print_Quads() {
    cout << endl ; 
    cout << "quad#\t\topcpode\t\t\t\tresult\t\targ1\t\targ2\t\tlabel\t\tline" << endl;
    cout << "----------------------------------------------------------------------------------------------------------------" << endl;
    for (unsigned int i = 0; i < Quads.size(); i++) {
        if(opcodeToString(Quads[i]->op).length()< 13){
           cout << i+1 << "\t\t" << opcodeToString(Quads[i]->op) << "    \t\t"; 
        }else{
           cout << i+1 << "\t\t" << opcodeToString(Quads[i]->op) << "\t\t";
        }
           
        if (Quads[i]->result && Quads[i]->result->sym){
            cout << Quads[i]->result->sym->getIdent() << "\t\t";
        }else{
            cout << exprValueToString(Quads[i]->result) << "\t\t";
        }
        if (Quads[i]->arg1 && Quads[i]->arg1->sym){
            cout << Quads[i]->arg1->sym->getIdent() << "\t\t";
        }else{
            cout << exprValueToString(Quads[i]->arg1) << "\t\t";
        }
        if (Quads[i]->arg2 && Quads[i]->arg2->sym){
            cout << Quads[i]->arg2->sym->getIdent() << "\t\t";
        }else{
            cout << exprValueToString(Quads[i]->arg2) << "\t\t";
        }
        
        cout << Quads[i]->label << "\t\t";
        cout << Quads[i]->line << "\t\t" << endl;

    }
}

string exprValueToString(Expr* expr) {
    if (expr == NULL) {
        return "NULL";
    }

    switch (expr->type) {
        case CONSTBOOL_E:
            return  std::get<bool>(expr->value) ? "true" : "false";
        case CONSTNUM_E:
            return (expr->value.index() == 1) ? std::to_string(std::get<double>(expr->value)) : std::to_string(std::get<int>(expr->value));
        case CONSTSTRING_E:
            return  std::get<string>(expr->value);
        default: 
            return "";
    }
}