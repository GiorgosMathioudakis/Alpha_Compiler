%{
    #include <stdio.h>
    #include <iostream>
    #include <stack>
    #include <fstream>
    #include <string>
    #include "symbol_Table.hpp"
    #include "intermediate_code.hpp"

    using namespace std;

    int yyerror(const char *yaccProvidedMessage);

    extern int yylineno;
    extern char* yytext;
    extern FILE* yyin;
    extern FILE* yyout;
    extern std::stack<unsigned int> commentStack;
    extern int yylex();

    void red() {
        cout << "\033[0;31m";
    }

    void reset() {
        cout << "\033[0;37m";
    }

    /* Global*/
    Symbol_Table symtable;
    unsigned int scope;
    bool isFunc;
    stack <string> Function_Stack; 
    bool func_is_ok; 
    string func_name; 
    int stmt_counter;
    int funcOpens;
    string anonymousName;
    int anonymousCounter;
    int function_check; 
    unsigned int currentLine;
    stack <bool> scopeStack;
    stack<unsigned int> scopeOffsetStack;
    string currentFunctionName;
    int newNameFunction;

    int loopcounter;
    stack <int> stack_lc;

    /*Offest vars */
    unsigned int programVarOffset;
    unsigned int functionLocalOffset;
    unsigned int formalArgOffset;
    unsigned int scopeSpaceCounter;
    unsigned int tempCounter;

    vector<Quad*> Quads;
%}

%start program

%define parse.error verbose
%output "parser.cpp" 

%code requires {
    #include "symbol_Table.hpp"
    #include "intermediate_code.hpp"
}

%union{
    char*   string;
    int     integer;
    double  real;
    struct Expr* expression;
    unsigned int quad69;
    Symbol* symbol; 
    Call* call;
    struct stmt_t {
        int breaklist, contlist;
    }s;
    struct _for{
        unsigned int enter, test;
    }f;
}

%token <string> IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token <string> ASSIGNMENT PLUS MINUS MULTIPLY DIVIDE MODULUS INCREMENT DECREMENT LESS_THAN GREATER_THAN LESS_THAN_OR_EQUAL GREATER_THAN_OR_EQUAL EQUAL NOT_EQUAL
%token <string> LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET PERIOD COMMA COLON SEMICOLON RIGHT_BRACKET LEFT_BRACKET RIGHT_PARENTHESIS LEFT_PARENTHESIS DOUBLE_COLON DOUBLE_PERIOD
%token <string> ID
%token <integer> INTEGER
%token <string> STRING
%token <real> REAL
%token <string> ERROR

%type program

%type <s> statements
%type <s> stmt
%type <s> loopstmt
%type <s> block
%type <s> break
%type <s> continue
%type <s> ifstmt

%type <expression> expr
%type <expression> term
%type <expression> assignexpr
%type <expression> primary
%type <expression> lvalue
%type <expression> member
%type <expression> call
%type <expression> elist
%type <expression> next
%type <expression> objectdef 
%type <expression> indexed
%type <expression> indexedelem
%type <expression> nextindexelem
%type <expression> const
%type <expression> returnstmt


%type <symbol> funcdef
%type <symbol> funcprefix
%type <call> normcall
%type <call> methodcall
%type <call> callsufix
%type <quad69> ifprefix
%type <quad69> elseprefix
%type <quad69> whilestart
%type <quad69> whilecond
%type <quad69> N
%type <quad69> M
%type <quad69> funcbody
%type <f> forprefix
%type <string>funcname
%type forstmt
%type loopstart
%type loopend
%type whilestmt
%type idlist
%type nextID

    /*Rules for priority*/
%right      ASSIGNMENT 
%left       OR
%left       AND
%nonassoc   EQUAL NOT_EQUAL  
%nonassoc   GREATER_THAN GREATER_THAN_OR_EQUAL LESS_THAN LESS_THAN_OR_EQUAL  
%left       PLUS MINUS
%left       MULTIPLY DIVIDE MODULUS
%right      NOT INCREMENT DECREMENT UMINUS
%left       PERIOD DOUBLE_PERIOD
%left       LEFT_BRACKET RIGHT_BRACKET
%left       LEFT_PARENTHESIS RIGHT_PARENTHESIS
%left       LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
%nonassoc   PUREIF
%nonassoc   ELSE

%%

program:
    statements{
    };

statements:
    statements stmt{
        resetTemp();
        $$.breaklist = mergelist($1.breaklist, $2.breaklist);
        $$.contlist = mergelist($1.contlist, $2.contlist); 
    } 
    | %empty {resetTemp(); $$.breaklist = 0;  $$.contlist = 0;}
    ;

stmt:
    expr SEMICOLON {resetTemp(); $$.breaklist = 0; $$.contlist = 0; }
    | ifstmt {resetTemp(); $$ = $1; }
    | returnstmt {resetTemp(); $$.breaklist = 0; $$.contlist = 0;}
    | forstmt {resetTemp(); $$.breaklist = 0; $$.contlist = 0;} 
    | whilestmt {resetTemp(); $$.breaklist = 0; $$.contlist = 0;}
    | break {$$ = $1; 
        if(loopcounter == 0){
            yyerror("break outside of loop");
        }
    }
    | continue {
        if(loopcounter == 0){
            yyerror("continue outside of statement");
        } 
        $$ = $1; 
    }
    | block {resetTemp(); $$ = $1; }
    | funcdef {resetTemp(); $$.breaklist =0; $$.contlist = 0;}
    | SEMICOLON {resetTemp(); $$.breaklist =0; $$.contlist = 0;}
    ;

expr: 
    term{$$ = $1;}
      | expr PLUS expr{
           if( isValidArithmeticOperation($1,$3) ){
                $$ = newExpr(ARITHMEXPR_E);
                $$->sym = newTemp();
                $$->type = const_check($1,$3);
                emit(IOP_ADD, $1, $3, $$, 0, yylineno);
            }else{
                yyerror("Non numeric value in arithmetic expression!");
            }
      }
      | expr MINUS expr {
        if( isValidArithmeticOperation($1,$3) ){
                $$ = newExpr(ARITHMEXPR_E);
                $$->sym = newTemp();
                $$->type = const_check($1,$3);
                emit(IOP_SUB, $1, $3, $$, 0, yylineno);
            }else{
                yyerror("Non numeric value in arithmetic expression!");
            }
      } 
      | expr MULTIPLY expr {
        if( isValidArithmeticOperation($1,$3) ){
                $$ = newExpr(ARITHMEXPR_E);
                $$->sym = newTemp();
                $$->type = const_check($1,$3);
                emit(IOP_MUL, $1, $3, $$, 0, yylineno);
            }else{
                yyerror("Non numeric value in arithmetic expression!");
            }
      }
      | expr DIVIDE expr {
        if( isValidArithmeticOperation($1,$3) ){
                $$ = newExpr(ARITHMEXPR_E);
                $$->sym = newTemp();
                $$->type = const_check($1,$3);
                emit(IOP_DIV, $1, $3, $$, 0, yylineno);
            }else{
                yyerror("Non numeric value in arithmetic expression!");
            }
      }
      | expr MODULUS expr {
        if( isValidArithmeticOperation($1,$3) ){
                $$ = newExpr(ARITHMEXPR_E);
                $$->sym = newTemp();
                $$->type = const_check($1,$3);
                emit(IOP_MOD, $1, $3, $$, 0, yylineno);
            }else{
                yyerror("Non numeric value in arithmetic expression!");
            }
      } 
      | expr LESS_THAN expr {
        if(!isValidArithmeticOperation($1,$3)){
                yyerror("ERROR");
                $$=NULL;
            }else { 
                $$ = newExpr(BOOLEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();
                
                emit(IOP_IF_LESS, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(false), NULL, $$, 0, yylineno);
                emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(true), NULL, $$, 0, yylineno);
            }



        
            // if($1->type == BOOLEXPR_E) {
                
            // }

            // if($3->type == BOOLEXPR_E){

            // }
            // $$ = newExpr(BOOLEXPR_E);
            // $$->sym = newTemp();
            // emit(IOP_IF_LESS, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
            // emit(IOP_ASSIGN, $$, NULL, newExpr_bool(false), 0, yylineno);
            // emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
            // emit(IOP_ASSIGN, $$, NULL, newExpr_bool(true), 0, yylineno);
             
      }
      | expr GREATER_THAN expr {
        if(!isValidArithmeticOperation($1,$3)){
                yyerror("ERROR");
                $$=NULL;
            }else { 
                $$ = newExpr(BOOLEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();

                
                emit(IOP_IF_GREATER, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(false), NULL, $$, 0, yylineno);
                emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(true), NULL, $$, 0, yylineno);
            }
            // if($1->type == BOOLEXPR_E) {
                    
            //     }

            //     if($3->type == BOOLEXPR_E){

            //     }
            //     $$ = newExpr(BOOLEXPR_E);
            //     $$->sym = newTemp();
            //     emit(IOP_IF_GREATER, $1, $3, NULL, nextquadlabel()+3+1, yylineno);
            //     emit(IOP_ASSIGN, $$, NULL, newExpr_bool(false), 0, yylineno);
            //     emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
            //     emit(IOP_ASSIGN, NULL, NULL, newExpr_bool(true), 0, yylineno);
      } 
      | expr LESS_THAN_OR_EQUAL expr {
        if(!isValidArithmeticOperation($1,$3)){
                yyerror("ERROR");
                $$=NULL;
            }else { 
                $$ = newExpr(BOOLEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();
                
            
                emit(IOP_IF_LESSEQ, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(false), NULL, $$, 0, yylineno);
                emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(true), NULL, $$, 0, yylineno);
            }
            // if($1->type == BOOLEXPR_E) {
                    
            //     }

            //     if($3->type == BOOLEXPR_E){

            //     }
            //     $$ = newExpr(BOOLEXPR_E);
            //     $$->sym = newTemp();
            //     emit(IOP_IF_LESSEQ, $1, $3,NULL ,  nextquadlabel()+3+1, yylineno);
            //     emit(IOP_ASSIGN, $$, NULL, newExpr_bool(false), 0, yylineno);
            //     emit(IOP_JUMP, NULL, NULL,NULL, nextquadlabel()+2+1, yylineno);
            //     emit(IOP_ASSIGN, NULL, NULL, newExpr_bool(true), 0, yylineno);

      }
      | expr GREATER_THAN_OR_EQUAL expr {
        if(!isValidArithmeticOperation($1,$3)){
                yyerror("ERROR");
                $$=NULL;
            }else { 
                $$ = newExpr(BOOLEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();
                

                emit(IOP_IF_GREATEREQ, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(false), NULL, $$, 0, yylineno);
                emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(true), NULL, $$, 0, yylineno);
            }
            // if($1->type == BOOLEXPR_E) {
                    
            //     }

            //     if($3->type == BOOLEXPR_E){

            //     }
            //     $$ = newExpr(BOOLEXPR_E);
            //     $$->sym = newTemp();
            //     emit(IOP_IF_GREATEREQ, $1, $3,NULL , nextquadlabel()+3+1+1, yylineno);
            //     emit(IOP_ASSIGN, $$, NULL, newExpr_bool(false), 0, yylineno);
            //     emit(IOP_JUMP, NULL, NULL, NULL , nextquadlabel()+2+1+1 , yylineno);
            //     emit(IOP_ASSIGN, NULL, NULL, newExpr_bool(true), 0, yylineno);
          
      } 
      | expr EQUAL expr {
        if(!isValidArithmeticOperation($1,$3)){
                yyerror("ERROR");
                $$=NULL;
            }else { 
                $$ = newExpr(BOOLEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();
                
                emit(IOP_IF_EQ, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(false), NULL, $$, 0, yylineno);
                emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(true), NULL, $$, 0, yylineno);
            }
            // if($1->type == BOOLEXPR_E) {
                
            // }

            // if($3->type == BOOLEXPR_E){

            // }
            // $$ = newExpr(BOOLEXPR_E);
            // $$->sym = newTemp();
            // emit(IOP_IF_EQ, $1, $3, NULL , nextquadlabel()+3+1 , yylineno);
            // emit(IOP_ASSIGN, $$, NULL, newExpr_bool(false), 0, yylineno);
            // emit(IOP_JUMP, NULL, NULL, NULL , nextquadlabel()+2+1, yylineno);
            // emit(IOP_ASSIGN, NULL, NULL, newExpr_bool(true), 0, yylineno);
      }
      | expr NOT_EQUAL expr {
        if(!isValidArithmeticOperation($1,$3)){
                yyerror("ERROR");
                $$=NULL;
            }else { 
                $$ = newExpr(BOOLEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();
                
                emit(IOP_IF_NOTEQ, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(false), NULL, $$, 0, yylineno);
                emit(IOP_JUMP, NULL, NULL, NULL ,  nextquadlabel()+2+1, yylineno);
                emit(IOP_ASSIGN, newExpr_bool(true), NULL, $$, 0, yylineno);
            }
            // if($1->type == BOOLEXPR_E) {
                    
            //     }

            //     if($3->type == BOOLEXPR_E){

            //     }
            //     $$ = newExpr(BOOLEXPR_E);
            //     $$->sym = newTemp();
            //     emit(IOP_IF_NOTEQ, $1, $3, NULL , nextquadlabel()+3+1, yylineno);
            //     emit(IOP_ASSIGN, $$, NULL, newExpr_bool(false), 0, yylineno);
            //     emit(IOP_JUMP, NULL, NULL,NULL, nextquadlabel()+2+1,  yylineno);
            //     emit(IOP_ASSIGN, NULL, NULL, newExpr_bool(true), 0, yylineno);
      
        } 
      | expr AND expr {
            $$ = newExpr(BOOLEXPR_E);
            $$->sym = newTemp();
            emit(IOP_AND, $1, $3, $$, 0, yylineno);
      }
            
      | expr OR expr {
            $$ = newExpr(BOOLEXPR_E);
            $$->sym = newTemp();

            emit(IOP_OR, $1, $3, $$, 0, yylineno);
      }
      | assignexpr { $$ = $1;}
      ;
    

assignexpr : 
    lvalue ASSIGNMENT expr {
        if ($1 == NULL || $1->sym == NULL || $3 == NULL){
            //yyerror("An error occured ");
            $$ = NULL;
        }else{
            Symbol *symbol = $1->sym;
            if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
                yyerror("Function can't be assigned");
                $$ = NULL;
            }else if (!symbol->getActive() ){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }

            if($1->type == TABLEITEM_E){
                emit(IOP_TABLESETELEM, $1->index, $3, $1, 0, yylineno);
                $$ = emit_iftableitem($1,yylineno);
                $$->type = ASSIGNEXPR_E;
            }else{
                if($3 != NULL){
                    emit(IOP_ASSIGN, $3, NULL, $1, 0, yylineno);
                    Expr *result;
                    result = newExpr(ASSIGNEXPR_E);
                    result->sym = newTemp();
                    emit(IOP_ASSIGN, $1, NULL, result, 0, yylineno);
                    $$ = result;
                }
            }
        }
    }
    ;

term: 
    LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {$$ = $2;}
    | MINUS expr %prec UMINUS {
        if($2 == NULL){
            $$= NULL;
        }else{
            if(!check_arith($2)){
                yyerror("An error occured : Cant without arithmetic expression");
                $$= NULL;
            }else{
                $$ = newExpr(ARITHMEXPR_E);
                $$->sym = newTemp();
                $$->value = $$->sym->getIdent();
                emit(IOP_UMINUS,$2,NULL,$$,0,yylineno);
            }
        }
    }
    | NOT expr {
        $$ = newExpr(VAR_E); 
        $$->sym = newTemp();
        $$->value = $$->sym->getIdent();
        emit(IOP_NOT,$2,NULL,$$,0,yylineno); 
    } 
    | primary {$$ = $1;}
    | INCREMENT lvalue {
        if($2 == NULL || $2->sym == NULL ){
            yyerror("An Error occurred");
            $$ = NULL;
        }else{
            Symbol *symbol = $2->sym;
            if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
                yyerror("Function can't be incremented");
            }else{
                if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
                }
            }

            if($2->type == TABLEITEM_E){
                //if expression is ++<table_item>  , we need to increment and set the value
                $$ = emit_iftableitem($2,yylineno);
                emit(IOP_ADD, $$, newExpr_constnum(1), $$, 0, yylineno);
                emit(IOP_TABLESETELEM, $2, $2->index, $$, 0, yylineno);
            }else{
                emit(IOP_ADD,newExpr_constnum(1),$2,$2,0,yylineno);
                $$ = newExpr(ARITHMEXPR_E);

                if(isTempSymbol($2->sym)){
                    $$->sym = $2->sym;
                }else{
                    $$->sym = newTemp();
                    $$->value = $$->sym->getIdent();
                    emit(IOP_ASSIGN,$2,NULL,$$,0,yylineno);
                }
            }

        }
    }
    | lvalue INCREMENT {

        if($1 == NULL || $1->sym == NULL ){
            yyerror("An Error occurred");
            $$ = NULL;
        }else{
            Symbol *symbol = $1->sym;
            if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
                yyerror("Function can't be incremented");
            }else{
                if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
                }
            }

            if($1->type == TABLEITEM_E){
                //if expression is <table_item>++ , we need to make a 'dummy' expression to increment that and set the value
                $$ = emit_iftableitem($1,yylineno);
                Expr* dummy = emit_iftableitem($1,yylineno);
                
                emit(IOP_ASSIGN, dummy , NULL , $$ , 0, yylineno);
                emit(IOP_ADD, dummy, newExpr_constnum(1), dummy , 0, yylineno);
                emit(IOP_TABLESETELEM, $1, $1->index, dummy, 0, yylineno);
            }else{
                
                emit(IOP_ASSIGN,$1,NULL,$$,0,yylineno);
                emit(IOP_ADD,newExpr_constnum(1),$1,$$,0,yylineno);
            }

        }
  
    }
    | DECREMENT lvalue {
        if($2 == NULL || $2->sym == NULL ){
            yyerror("An Error occurred");
            $$ = NULL;
        }else{
            Symbol *symbol = $2->sym;
            if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
                yyerror("Function can't be decremented");
            }else{
                if(!symbol->getActive()){
                    symbol->setActive(true);
                    symtable.insertValue(symbol); 
                }
            }

            if($2->type == TABLEITEM_E){
                $$ = emit_iftableitem($2,yylineno);
                emit(IOP_SUB, $$, newExpr_constnum(1), $$, 0, yylineno);
                emit(IOP_TABLESETELEM, $2, $2->index, $$, 0, yylineno);
            }else{
                emit(IOP_SUB,newExpr_constnum(1),$2,$2,0,yylineno);
                $$ = newExpr(ARITHMEXPR_E);

                if(isTempSymbol($2->sym)){
                    $$->sym = $2->sym;
                }else{
                    $$->sym = newTemp();
                    $$->value = $$->sym->getIdent();
                    emit(IOP_ASSIGN,$2,NULL,$$,0,yylineno);
                }
            }
        }
    } 
    | lvalue DECREMENT {
        if($1 == NULL || $1->sym == NULL ){
            yyerror("An Error occurred");
            $$ = NULL;
        }else{
            Symbol *symbol = $1->sym;
            if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
                yyerror("Function can't be incremented");
            }else{
                if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
                }
            }

            if($1->type == TABLEITEM_E){
                //if expression is <table_item>++ , we need to make a 'dummy' expression to increment that and set the value
                $$ = emit_iftableitem($1,yylineno);
                Expr* dummy = emit_iftableitem($1,yylineno);
                emit(IOP_ASSIGN, dummy , NULL , $$ , 0, yylineno);
                emit(IOP_SUB, dummy, newExpr_constnum(1), dummy , 0, yylineno);
                emit(IOP_TABLESETELEM, $1, $1->index, dummy, 0, yylineno);
            }else{
                emit(IOP_ASSIGN,$1,NULL,$$,0,yylineno);
                emit(IOP_SUB,newExpr_constnum(1), $1, $$, 0, yylineno);
            }
        } 
    }
    ; 

block: 
    LEFT_CURLY_BRACKET{
        scope++; 
        if(scope > symtable.get_max_scope()){
            symtable.set_max_scope(scope);
        }
        scopeStack.push(isFunc);
        isFunc = false;
        } statements RIGHT_CURLY_BRACKET {symtable.hide(scope); scope--; scopeStack.pop(); $$ = $3;}
    ;

funcname: 
    ID {
        currentFunctionName = $1;
    }
    | %empty{
        currentFunctionName = "_f" + std::to_string(newNameFunction++);
    };

funcprefix: FUNCTION {currentLine = yylineno;} funcname {
    if(symtable.contains(currentFunctionName, LIBRARY_FUNCTION)){
        yyerror("function shadows library function");
        $$= NULL;
    }else if(symtable.lookup(currentFunctionName,scope)  != NULL){
        yyerror("function shadows other function or variable");
        $$=NULL;   
    }else{
        Symbol* func_symbol = new Symbol(USER_FUNCTION, currentFunctionName, yylineno, scope, true);
        emit(IOP_JUMP,NULL,NULL,NULL,0,yylineno);
        func_symbol->setAddress(nextquadlabel());
        emit(IOP_FUNCSTART,lvalue_expr(func_symbol),NULL,NULL,0,yylineno);

        scopeOffsetStack.push(currscopeoffset());
        inccurrscopeoffset();

        enterscopespace();
        resetformalargsoffset();

        symtable.insertValue(func_symbol);
        
        $$ = func_symbol;
    }
};

funcargs:
    LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS { 
        funcOpens++;
        func_is_ok = true;
        stack_lc.push(loopcounter);
        loopcounter = 0;
        enterscopespace();
        resetfunctionlocalsoffset();
    };

funcbody:
    block{
        $$ = currscopeoffset();
        exitscopespace();
    };

funcdef:
    funcprefix funcargs funcbody{
        if($1 == NULL){
            $$= NULL;
        }else{
            exitscopespace();
            $1->setTotalLocals($3);
            restorecurrscopeoffset(scopeOffsetStack.top());  //Restore previous scope offset
            scopeOffsetStack.pop();
            funcOpens--;
            loopcounter = stack_lc.top();
            stack_lc.pop();
            $$=$1;
            emit(IOP_FUNCEND,lvalue_expr($1),NULL,NULL,0,yylineno);
            patchlabel($1->getAddress()-1,nextquadlabel()+1);
        }
    }

idlist:
    ID { 
            Symbol* function = symtable.lookup(currentFunctionName, scope);
            if(symtable.contains($1,LIBRARY_FUNCTION)){
                yyerror("argument shadows library function");
                //$$ = NULL;
            }else if(function->containsArgument($1)){
                yyerror("argument redeclaration");
                //$$ = NULL;
            }else{
                Symbol* new_symbol = new Symbol(FORMAL_VAR , $1 , yylineno , scope+1 , true);
                new_symbol->setSpace(FORMAL_ARG);
                new_symbol->setOffset(currscopeoffset());
                symtable.insertValue(new_symbol);
                function->setArg(new_symbol);
                inccurrscopeoffset();
                //$$=lvalue_expr(new_symbol);
            }
        
    } nextID
    | %empty
    ;

nextID:
    COMMA ID  {
            Symbol* function = symtable.lookup(currentFunctionName , scope);
            if(symtable.contains($2,LIBRARY_FUNCTION)){
                yyerror("argument shadows library function");
               //$$= NULL;
            }else if(function->containsArgument($2)){
                yyerror("argument redeclaration");
                //$$ = NULL;
            }else{
                Symbol* new_symbol = new Symbol(FORMAL_VAR , $2 , yylineno , scope+1 , true);
                new_symbol->setSpace(FORMAL_ARG);
                new_symbol->setOffset(currscopeoffset());
                symtable.insertValue(new_symbol);
                function->setArg(new_symbol);
                inccurrscopeoffset();
                //$$ = lvalue_expr(new_symbol);
            }
    }nextID
    | %empty
    ;

primary: 
    call {}
    | objectdef {$$ = $1;} 
    | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {
        $$ = newExpr(PROGRAMFUNC_E);
        $$->sym = $2;
        $$->value = $$->sym->getIdent();
    } 
    | const {$$ = $1;}
    | lvalue{
        Symbol* symbol = $1->sym;
        if($1 == NULL && $1->sym == NULL){
           yyerror("An error came up in primary");
           $$ = NULL;
        }else{
            $$ = emit_iftableitem($1,yylineno);
            Symbol *newsym = $1->sym;

            if(!symbol->getActive() ){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }

            if(newsym->getType() == USER_FUNCTION ){
                $$ = change_type($$,PROGRAMFUNC_E);
            }else if(newsym->getType() == LIBRARY_FUNCTION){
                $$ = change_type($$,LIBRARYFUNC_E);
            }else{
                $$ = change_type($$,VAR_E);
            }
        }
    }
    ;
    
lvalue
    : ID{
        Symbol* search = symtable.lookup($1, scope, scopeStack);
        symbol_T type = GLOBAL_VAR;

        if (scope != 0){
            type = LOCAL_VAR;
        }

        if( search == NULL ){
            Symbol* newsym = new Symbol(type, $1, yylineno, scope, false);
            newsym->setOffset(currscopeoffset());
            newsym->setSpace(currscopespace());
            inccurrscopeoffset();
            $$ = lvalue_expr(newsym);
            
        }else{
            if( search->getType() == __ERROR__){
                yyerror("Cannot access the variable");
                $$ = NULL;
            }else{
                $$ = lvalue_expr(search); 
            }
        } 
    }
    | LOCAL ID{
        Symbol* search = symtable.lookup($2, scope);
        symbol_T type = LOCAL_VAR;

        if(scope == 0){
            type = GLOBAL_VAR;
        }

        if(search != NULL && search->getScope() == scope){
            $$ = lvalue_expr(search);
        }else if(!symtable.contains($2, LIBRARY_FUNCTION)) {
            Symbol* newsym = new Symbol(type, $2, yylineno , scope, false);
            newsym->setOffset(currscopeoffset());
            newsym->setSpace(currscopespace());
            inccurrscopeoffset();
            $$ = lvalue_expr(newsym);
        }else if(symtable.contains($2, LIBRARY_FUNCTION)){
            yyerror("ID shadows a library fucntion");
            $$ = NULL;
        }     
    }
    | DOUBLE_COLON ID { 
        Symbol* search = symtable.get($2,0);
        
        if (search != NULL) {
            $$ = lvalue_expr(search);
        }else{
            $$ = NULL;  
            yyerror("ERROR: undefined global variable"); 
        }
    }
    | member { $$ = $1; };    

member
    :lvalue PERIOD ID{
        if($1 == NULL || $1->sym == NULL ){
            $$ = NULL;
        }else{
            Symbol *symbol = $1->sym;
        
            if(symbol == NULL){
            
            }else if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }   

            $$ = member_item($1 , $3);
        }


    }
    | lvalue LEFT_BRACKET expr RIGHT_BRACKET{
        if( $1 == NULL || $1->sym == NULL || $3 == NULL){
            $$ = NULL;
        }else { 
            Symbol *symbol = $1->sym;
            if(symbol == NULL){
            
            }else if(!symbol->getActive()){
                
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }   

            $1 = emit_iftableitem($1,yylineno);

            $$ = newExpr(TABLEITEM_E);
            $$->sym = $1->sym;
            $$->index = $3;
        }

    }
    | call PERIOD ID {
        if($1 == NULL || $1->sym == NULL){
            $$ = NULL;
        }else{
            Symbol *symbol = $1->sym;
            if(symbol == NULL){
            
            }else if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }   

            $$ = member_item($1 , $3);
        }
    }
    | call LEFT_BRACKET expr RIGHT_BRACKET{
        if($1 == NULL || $1->sym == NULL || $3 == NULL){
            $$ = NULL;
        }else{
            Symbol *symbol = $1->sym;
            if(symbol == NULL){
            
            }else if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }   

            $1 = emit_iftableitem($1,yylineno);

            $$ = newExpr(TABLEITEM_E);
            $$->sym = $1->sym;
            $$->index = $3;
        }
    }
    ;

objectdef 
    :LEFT_BRACKET elist RIGHT_BRACKET{

        $$ = newExpr(NEWTABLE_E);
        $$->sym = newTemp();
        $$->value = $$->sym->getIdent();
        emit(IOP_TABLECREATE , $$ , NULL , NULL , 0 , yylineno);

        Expr* temp = $2;
        int i = 0;
        while(temp !=NULL){
            // cout << newExpr_constnum(i)->sym->getIdent() << endl;
            emit(IOP_TABLESETELEM, newExpr_constnum(i++) , temp , $$ , 0 ,yylineno );
            temp = temp->next;
        }
    }
    | LEFT_BRACKET indexed RIGHT_BRACKET {
        $$ = newExpr(NEWTABLE_E);
        $$->sym = newTemp();
        $$->value = $$->sym->getIdent();
        emit(IOP_TABLECREATE , $$ , NULL , NULL , 0 ,yylineno);
        int i = 0 ; 
        Expr* temp = $2;
        while(temp != NULL){
            emit(IOP_TABLESETELEM ,temp , temp->index , $$ , 0 , yylineno);
            temp = temp->next;
        }

    }
    ;

indexed 
    : indexedelem nextindexelem{
        $$ = $1 ; 
            if( $$ != NULL ) $$->next = $2;
    }
    ;

nextindexelem 
    : COMMA indexedelem nextindexelem {
        $$ = $2 ; 
        if( $$ != NULL ) $$->next = $3;
    }
    | %empty{
        $$ = NULL; 
    }
    ;

indexedelem : LEFT_CURLY_BRACKET expr COLON expr RIGHT_CURLY_BRACKET{
    $$ = $2;
    if($$ != NULL){
        $$->index = $4;
    }
}
    ; 

elist
    :expr next {
         $$ = $1 ; 
        if( $$ != NULL ) $$->next = $2;
    }
    | %empty{
        $$ = NULL ; 
    }
    ;

next
    : COMMA expr next{
        $$ = $2 ; 
        if( $$ != NULL ) $$->next = $3;
    }
    | %empty{
        $$ = NULL;
    }
    ;

const : INTEGER{ $$ = newExpr_constnum ( (int)yylval.integer ); }
    | REAL { $$ = newExpr_constnum ( (double)yylval.real ); }
    | STRING{ $$ = newExpr_conststring (yylval.string); }
    | NIL{ $$ = newExpr(NIL_E);}
    | TRUE{ $$ = newExpr_bool (true); }
    | FALSE{ $$ = newExpr_bool (false); }
    ;

call: call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS   {
            if($1 == NULL){
                $$= NULL;
            }else{
                $$ = make_call($1,ReverseElist($3),yylineno);
            }}
      | lvalue callsufix { 
            if($1 == NULL){
                $$ = NULL;
            }else{
                //Expr* lvaluetemp = emit_iftableitem($1,yylineno);
                $1 = emit_iftableitem($1,yylineno);

                if($2->method){ 
                    //Expr *temp = lvaluetemp;
                    Expr *temp = $1;
                    //lvaluetemp = emit_iftableitem(member_item(temp,$2->name),yylineno);
                    $1 = emit_iftableitem(member_item(temp,$2->name),yylineno);
                    $2->eList.push_front(temp);
                }

                $$ = make_call($1, $2->eList, yylineno);
                //$$ = make_call(lvaluetemp, $2->eList, yylineno);

                Symbol *symbol = $1->sym;

                if(symbol == NULL){

                }else if(!symbol->getActive()){
                    symbol->setActive(true);
                    symtable.insertValue(symbol); 
                }   
            }
      } 
      | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {
            if($2 == NULL){
                $$= NULL;
            }else{
                Expr *func = newExpr(PROGRAMFUNC_E);
                func->sym = $2;
                $$ = make_call(func,ReverseElist($5),yylineno);
            }
      }
      ;
      
callsufix: normcall {$$=$1;}
           | methodcall {$$=$1;};

normcall
    : LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {
        Call* temp = new Call();
        temp->eList = ReverseElist($2);
        temp->method = 0;
        temp->name = "NULL"; 
        $$ = temp;
};

methodcall
    : DOUBLE_PERIOD ID LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {
        Call* temp = new Call();
        temp->eList = ReverseElist($4);
        temp->method = 1;
        temp->name = $2;
        $$ = temp;
};

ifprefix: IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS{
        emit(IOP_IF_EQ, $3, newExpr_bool(true), NULL, nextquadlabel()+2+1, yylineno);
        $$ = nextquadlabel();
        emit(IOP_JUMP, NULL, NULL, NULL, 0, yylineno);
        
};

elseprefix: ELSE { 
        $$=nextquadlabel();
        emit(IOP_JUMP,NULL,NULL,NULL,0,yylineno); 
    };

ifstmt: ifprefix stmt {
            patchlabel($1,nextquadlabel()+1);
            $$=$2;
        }
        | ifprefix stmt elseprefix stmt{
            patchlabel($1, $3 + 1 + 1);
            patchlabel($3,nextquadlabel()+1);
            $$.breaklist = mergelist($2.breaklist, $4.breaklist);
            $$.contlist = mergelist($2.contlist, $4.contlist);
        };

returnstmt: 
        RETURN SEMICOLON {
            if(funcOpens == 0){
                yyerror("return outside of function");
            } 

            emit(IOP_RET, NULL, NULL, NULL, 0, yylineno);
        }
        | RETURN expr SEMICOLON {
            if(funcOpens == 0){
                yyerror("return outside of function");
            } 

            emit(IOP_RET, NULL, NULL, $2, 0, yylineno);
        }
        ;

N: {
    $$ = nextquadlabel();
    emit(IOP_JUMP, NULL, 0, NULL, 0, yylineno);
};

M: {
    $$ = nextquadlabel();
};

forprefix: FOR {currentLine = yylineno;} LEFT_PARENTHESIS elist SEMICOLON M expr SEMICOLON{
        $$.test = $6;
        $$.enter = nextquadlabel();
        emit(IOP_IF_EQ, newExpr_bool(true), 0 , $7, 0, yylineno);

};

forstmt: forprefix N elist RIGHT_PARENTHESIS N loopstmt N{
    patchlabel($1.enter, $5+1+1);
    patchlabel($2, nextquadlabel()+1 );
    patchlabel($5, $1.test+1);
    patchlabel($7, $2+1+1);
    patchlist($6.breaklist, nextquadlabel()+1 );
    patchlist($6.contlist, $2+1+1);
};
       

whilestart: WHILE {
    $$ = nextquadlabel()+1;
}
;

whilecond: LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {
    emit(IOP_IF_EQ, $2, newExpr_bool(true), NULL, nextquadlabel()+2+1, yylineno);
    $$ = nextquadlabel();
    emit(IOP_JUMP, NULL, 0, NULL , 0 , yylineno);
    
};

whilestmt: whilestart whilecond loopstmt {
    emit(IOP_JUMP, NULL, NULL,  NULL, $1, yylineno);
    patchlabel($2, nextquadlabel()+1);
    patchlist($3.breaklist, nextquadlabel()+1);
    patchlist($3.contlist, $1);
};

loopstart:{ ++loopcounter; }
;

loopend: { --loopcounter; }
;

loopstmt: loopstart stmt loopend { $$ = $2; };

break: BREAK SEMICOLON {
    resetTemp();
    emit(IOP_JUMP, NULL, NULL, NULL, 0, yylineno);
    $$.breaklist = 0;
    $$.contlist = 0;
    $$.breaklist = makelist( nextquadlabel()-1 );
};

continue: CONTINUE SEMICOLON {
    resetTemp();
    emit(IOP_JUMP, NULL, NULL, NULL, 0, yylineno);
    $$.breaklist = 0;
    $$.contlist = 0;
    $$.contlist = makelist( nextquadlabel()-1 );
};


%%

int yyerror(const char* yaccProvidedMessage){
    red();
    cout << yaccProvidedMessage << " at line: " << yylineno << endl;
    reset();
    return 0;
}

int main(int argc ,char** argv){
    FILE *file = freopen("quads.txt", "w", stdout);
    if(argc > 1 ){
        if(!(yyin = fopen(argv[1],"r"))) {
            fprintf(stderr, "Cannot read file: %s\n" , argv[1]);    
            return 1;
        }
    }
    else{
        yyin = stdin;
    }

    //initializations
    symtable = Symbol_Table();
    isFunc = false;
    func_is_ok = false ; 
    anonymousName = " ";
    anonymousCounter = 1;
    function_check = -1;
    stack <bool> scopeStack;
    stmt_counter = 0;
    funcOpens = 0;
    loopcounter = 0;
    newNameFunction = 0;

    programVarOffset = 0;
    functionLocalOffset = 0;
    formalArgOffset = 0;
    scopeSpaceCounter = 1;
    tempCounter = 1;

    

    // output 
    yyparse();


    print_Quads();
    //symtable.printSymTable();
    
    if(yyin){
        if(!commentStack.empty()){
            cout << "COMMENT: " << "UNBALANCED COMMENT" << endl;
        }
    }
    
    fclose(yyin);
    
    
    freopen("/dev/tty", "w", stdout);
    fclose(file);
    return 0;
}