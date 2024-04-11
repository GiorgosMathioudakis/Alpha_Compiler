%{
    #include <stdio.h>
    #include <iostream>
    #include <stack>
    #include <fstream>
    #include "symbol_Table.hpp"

    struct symbol_S{
        Symbol* symbol;
    };
    
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
    unsigned int scope = 0;
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

%}

%start program

%define parse.error verbose
%output "parser.cpp" 

%code requires {
    #include "symbol_Table.hpp"
}

%union{
    char*   string;
    int     integer;
    double  real;
    unsigned int expression;
    Symbol* symbol ; 
}


%token <string> IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE AND NOT OR LOCAL TRUE FALSE NIL
%token <string> ASSIGNMENT PLUS MINUS MULTIPLY DIVIDE MODULUS INCREMENT DECREMENT LESS_THAN GREATER_THAN LESS_THAN_OR_EQUAL GREATER_THAN_OR_EQUAL EQUAL NOT_EQUAL
%token <string> LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET PERIOD COMMA COLON SEMICOLON RIGHT_BRACKET LEFT_BRACKET RIGHT_PARENTHESIS LEFT_PARENTHESIS DOUBLE_COLON DOUBLE_PERIOD
%token <string> ID
%token <integer> INTEGER
%token <string> STRING
%token <real> REAL
%token <string> ERROR

/*Non - terminal token */
%type<expression> expr
%type<symbol> lvalue
%type<expression> term
%type<expression> primary
%type<expression> assignexpr
 

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
    }
    | %empty
    ;

stmt:
    expr SEMICOLON {}
    | ifstmt {}
    | returnstmt {}
    | forstmt {} 
    | whilestmt {}
    | BREAK SEMICOLON {
        if(stmt_counter == 0) {
            yyerror("break outside of statement");
        }
    }
    | CONTINUE SEMICOLON {
        if(stmt_counter == 0){
            yyerror("continue outside of statement");
        } 
    }
    | block {}
    | funcdef {}
    | SEMICOLON {}
    ;

expr: 
    term{$$ = $1;}
      | expr PLUS expr{
            if($1 == function_check || $3 == function_check){
                yyerror("Function can't be added");
            }
      }
      | expr MINUS expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be subtracted");
        }
      } 
      | expr MULTIPLY expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be multiplied");
        }
      }
      | expr DIVIDE expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be divided"); 
        }
      }
      | expr MODULUS expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be modulated");
        }
      } 
      | expr LESS_THAN expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be compared"); 
        }
      }
      | expr GREATER_THAN expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be compared"); 
        }
      } 
      | expr LESS_THAN_OR_EQUAL expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be compared"); 
        }
      }
      | expr GREATER_THAN_OR_EQUAL expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be compared");
        }
      } 
      | expr EQUAL expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be compared");
        }
      }
      | expr NOT_EQUAL expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be compared");
        }
      } 
      | expr AND expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be in a logical expression");
        }
      }
      | expr OR expr {
        if($1 == function_check || $3 == function_check){
            yyerror("Function can't be in a logical expression");
        }
      }
      | assignexpr {}
      ;
    

assignexpr : 
    lvalue ASSIGNMENT expr {
        Symbol* symbol = $1;

        if (symbol == NULL){
            //do nothing
        }else if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
            yyerror("Function can't be assigned");
        }else if (!symbol->getActive() ){
            symbol->setActive(true);
            symtable.insertValue(symbol); 
        }
    }
    ;

term: 
    LEFT_PARENTHESIS expr RIGHT_PARENTHESIS {}
    | MINUS expr %prec UMINUS {}
    | NOT expr {} 
    | primary {$$ = $1;}
    | INCREMENT lvalue {
        Symbol *symbol = $2;
        if(symbol == NULL){

        }else if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
            yyerror("Function can't be incremented");
        }else if(!symbol->getActive()){
            symbol->setActive(true);
            symtable.insertValue(symbol); 
        }    
    }
    | lvalue INCREMENT {
        Symbol *symbol = $1;

        if(symbol == NULL){

        }else if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
            yyerror("Function can't be incremented");
        }else if(!symbol->getActive()){
            symbol->setActive(true);
            symtable.insertValue(symbol); 
        }   
    }
    | DECREMENT lvalue {
        Symbol *symbol = $2;
        
        if(symbol == NULL){

        }else if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
            yyerror("Function can't be decremented");
        }else if(!symbol->getActive()){
            symbol->setActive(true);
            symtable.insertValue(symbol); 
        }   
    } 
    | lvalue DECREMENT {
        Symbol *symbol = $1;
        if(symbol == NULL){

        }else if(symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION){
            yyerror("Function can't be decremented");
        }else if(!symbol->getActive()){
            symbol->setActive(true);
            symtable.insertValue(symbol); 
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
        } statements RIGHT_CURLY_BRACKET {symtable.hide(scope); scope--; scopeStack.pop();}
    ;

funcdef:
    FUNCTION ID {
            Function_Stack.push($2);
            symbol_T type = USER_FUNCTION;
            func_is_ok = false;  // flag to check if function name is not in use or a lib function
            func_name = "invalid"; 
    

            if( symtable.contains($2 , LIBRARY_FUNCTION ) ) {
                yyerror("function shadows library function");
            }else if( symtable.contains($2 , scope) ) {
                yyerror("function shadows other function or variable");
            }else {
                func_is_ok = true;
                symtable.insertValue(new Symbol(USER_FUNCTION, $2, yylineno, scope, true));
                func_name = $2 ; 
            }
    } LEFT_PARENTHESIS idlist RIGHT_PARENTHESIS {isFunc = true; ++funcOpens;} block {--funcOpens; Function_Stack.pop();}
    | FUNCTION {
        func_is_ok  = true ;
        currentLine = yylineno;
        anonymousName = "_f" + to_string(anonymousCounter++);
        symtable.insertValue(new Symbol(USER_FUNCTION, anonymousName, currentLine, scope, true));
        func_name = anonymousName ; 
        Function_Stack.push(func_name);
    }LEFT_PARENTHESIS  idlist RIGHT_PARENTHESIS{++funcOpens; isFunc = true;} block {--funcOpens; Function_Stack.pop();}
    ;

idlist:
    ID {
        if(func_is_ok){
            Symbol* function = symtable.lookup(func_name, scope);
            if(symtable.contains($1,LIBRARY_FUNCTION)){
                yyerror("argument shadows library function");
            }else if(function->containsArgument($1)){
                yyerror("argument redeclaration");
            }else{
                Symbol* new_symbol = new Symbol(FORMAL_VAR , $1 , yylineno , scope+1 , true);
                symtable.insertValue(new_symbol);
                function->setArg(new_symbol);
            }
        }
    } nextID 
    | %empty
    ;

nextID:
    COMMA ID {
        if(func_is_ok){
            Symbol* function = symtable.lookup(func_name , scope);
            if(symtable.contains($2,LIBRARY_FUNCTION)){
                yyerror("argument shadows library function");
            }else if(function->containsArgument($2)){
                yyerror("argument redeclaration");
            }else{
                Symbol* new_symbol = new Symbol(FORMAL_VAR , $2 , yylineno , scope+1 , true);
                symtable.insertValue(new_symbol);
                function->setArg(new_symbol);
            }
        }
    } nextID
    | %empty
    ;

primary: 
    call {}
    | objectdef {} 
    | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS {} 
    | const {}
    | lvalue{
        Symbol* symbol = $1;
        if(symbol == NULL){
           
        }else{
            if((symbol->getType() == LIBRARY_FUNCTION || symbol->getType() == USER_FUNCTION)){
                $$ = function_check;
            }

            if( !symbol->getActive() ){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
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
            $$ = new Symbol(type, $1, yylineno, scope, false);
        }else{
            if( search->getType() == __ERROR__){
                yyerror("Cannot access the variable");
                $$ = NULL;
            }else{
                $$ = search; 
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
            $$ = search;
        }else if(!symtable.contains($2, LIBRARY_FUNCTION)) {
            $$ = new Symbol(type, $2, yylineno , scope, false);
        }else if(symtable.contains($2, LIBRARY_FUNCTION)){
            yyerror("ID shadows a library fucntion");
            $$ = NULL;
        }     
    }
    | DOUBLE_COLON ID { 
        Symbol* search = symtable.get($2,0);
        
        if (search != NULL) {
            $$ = search;
        }else{
            $$ = NULL;  
            yyerror("ERROR: undefined global variable"); 
        }
    }
    | member {
        $$ = NULL;
    }
    ;    

member: lvalue PERIOD ID{
        Symbol *symbol = $1;
       
        if(symbol == NULL){
        
        }else if(!symbol->getActive()){
            symbol->setActive(true);
            symtable.insertValue(symbol); 
        }   

    }
    | lvalue LEFT_BRACKET expr RIGHT_BRACKET{
        Symbol *symbol = $1;
        if(symbol == NULL){
        
        }else if(!symbol->getActive()){
            
            symbol->setActive(true);
            symtable.insertValue(symbol); 
        }   


    }
    | call PERIOD ID {}
    | call LEFT_BRACKET expr RIGHT_BRACKET{}
    ;

objectdef : LEFT_BRACKET elist RIGHT_BRACKET{}
    | LEFT_BRACKET indexed RIGHT_BRACKET {}
    ;

indexed : indexedelem nextindexelem{}
    ;

nextindexelem : COMMA indexedelem nextindexelem {}
    | %empty
    ;

indexedelem : LEFT_CURLY_BRACKET expr COLON expr RIGHT_CURLY_BRACKET{}
    ;

elist: expr nextexpr {}
    | %empty
    ;

nextexpr: COMMA expr nextexpr{}
    | %empty
    ;

const : INTEGER{}
    | REAL {}
    | STRING{}
    | NIL{}
    | TRUE{}
    | FALSE{}
    ;

call: call LEFT_PARENTHESIS elist RIGHT_PARENTHESIS   {}
      | lvalue callsufix {
            Symbol *symbol = $1;

            if(symbol == NULL){

            }else if(!symbol->getActive()){
                symbol->setActive(true);
                symtable.insertValue(symbol); 
            }   

      } 
      | LEFT_PARENTHESIS funcdef RIGHT_PARENTHESIS LEFT_PARENTHESIS elist RIGHT_PARENTHESIS
      ;
      
callsufix: normcall {}
           | methodcall {}
           ;

normcall: LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
        ;

methodcall: DOUBLE_PERIOD ID LEFT_PARENTHESIS elist RIGHT_PARENTHESIS {}
            ;

ifstmt: IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt %prec PUREIF {}  
        | IF LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt ELSE stmt {}
        ;

returnstmt: 
        RETURN SEMICOLON {
            if(funcOpens == 0){
                yyerror("return outside of function");
            } 
        }
        | RETURN expr SEMICOLON {
            if(funcOpens == 0){
                yyerror("return outside of function");
            } 
        }
        ;

forstmt: 
       FOR {currentLine = yylineno; stmt_counter++;} LEFT_PARENTHESIS elist SEMICOLON expr SEMICOLON elist RIGHT_PARENTHESIS stmt {stmt_counter--;} {}
       ;

whilestmt : 
        WHILE {currentLine = yylineno; stmt_counter++;}  LEFT_PARENTHESIS expr RIGHT_PARENTHESIS stmt {stmt_counter--;}{} 
        ;


%%

int yyerror(const char* yaccProvidedMessage){
    red();
    cout << yaccProvidedMessage << " at line: " << yylineno << endl;
    reset();
    return 0;
}

int main(int argc ,char** argv){
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

    // output 
    yyparse();
    symtable.printSymTable();
    
    if(yyin){
        if(!commentStack.empty()){
            cout << "COMMENT: " << "UNBALANCED COMMENT" << endl;
        }
    }
    
    fclose(yyin);
    return 0;
}