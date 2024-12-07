#ifndef SYMBOL_TABLE_HPP
#define SYMBOL_TABLE_HPP

#include <algorithm> // For std::sort
#include <vector>
#include <list> 
#include <map>
#include <stack>
#include <fstream>
#include <iostream>
#include <string>
using namespace std;

typedef enum{GLOBAL_VAR, LOCAL_VAR, FORMAL_VAR, USER_FUNCTION, LIBRARY_FUNCTION, __ERROR__} symbol_T;

const string state_str[] = {"global variable" , "local variable", "formal argument", "user function", "library function"};

typedef enum { PROGRAM_VAR , FUNCTION_LOCAL , FORMAL_ARG } scopespace_t;


class Symbol{ 
    private: 
        string ident;
        bool isActive;
        symbol_T type;
        unsigned int scope;
        unsigned int lineno;
        list <Symbol*> func_args;
        unsigned int offset;
        scopespace_t space; 
        unsigned int address ;
        unsigned int TotalLocals;
        
    public:
        Symbol(symbol_T type, string ident,  unsigned int lineno, unsigned int scope, bool isActive){
            this->ident = ident;
            this->isActive = isActive;
            this->scope = scope;
            this->lineno = lineno;
            this->type = type;
            func_args = list<Symbol*>(); 
        }

        scopespace_t getSpace(){
            return space;
        }

        unsigned int getTotalLocals(){
            return TotalLocals;
        }

        unsigned int getAddress(){
            return address;
        }

        unsigned int getOffset(){
            return offset;
        }

        symbol_T getType(){
            return type;
        }

        string getIdent(){
            return ident;
        }

        unsigned int getLineno(){
            return lineno;
        }

        unsigned int getScope(){
            return scope;
        }

        bool getActive(){
            return isActive;
        }

        Symbol *getArgs(string ident){
            for (auto it = func_args.begin(); it != func_args.end(); it++) {
                if((*it)->getIdent() == ident){
                    return (*it);
                }
            }
            return NULL; 
        }

        void setTotalLocals(unsigned int TotalLocals){
            this->TotalLocals = TotalLocals;
        }

        void setSpace(scopespace_t space){
            this->space = space;
        }

        void setOffset(unsigned int offset){
            this->offset = offset;
        }

        bool containsArgument(string ident){
            return getArgs(ident) != NULL;
        }

        void setArg(Symbol* arg){
            func_args.push_back(arg);
        }
        void setAddress(unsigned int address){
            this->address = address;
        }

        void setType(symbol_T type){
            this->type = type;
        }

        void setIdent(string ident){
            this->ident = ident;
        }

        void setLineno(unsigned int lineno){
            this->lineno = lineno;
        }

        void setScope(unsigned int scope){
            this->scope = scope;
        }

        void setActive(bool isActive){
            this->isActive = isActive;
        }

};


class Symbol_Table{
    private:
        multimap <string, Symbol*> map_table;
        int max_scope;

    public:
        Symbol_Table(){
            map_table = multimap<string , Symbol*>();
            max_scope = 0;
            insertValue(new Symbol(LIBRARY_FUNCTION, "print", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "input", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "objectmemberkeys", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "objecttotalmembers", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "objectcopy", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "totalarguments", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "argument", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "typeof", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "strtonum", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "sqrt", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "cos", 0, 0, true) );
            insertValue(new Symbol(LIBRARY_FUNCTION, "sin", 0, 0, true) );  
        }

           
        void insertValue(Symbol* symbol){ 
            map_table.insert({symbol->getIdent() , symbol });
        }

        int get_max_scope(){
            return max_scope;
        }

        void set_max_scope(int scope){
            max_scope = scope;
        }

        Symbol* getSymbol(string ident){
            auto get = map_table.find(ident);   
            return get->second;
        }

        Symbol *lookup(string ident){
            multimap<string, Symbol*>::iterator it2; 
            for (auto it2 = map_table.begin(); it2 != map_table.end(); ++it2){
                if(it2->second->getActive() && it2->second->getIdent() == ident){

                    return it2->second;
                }
            }   
            return NULL; 
        }

        Symbol *lookup(string ident,unsigned int scope){
            multimap<string, Symbol*>::iterator it2;
            int currscope = scope;

            while(currscope >= 0){
                for (auto it2 = map_table.begin(); it2 != map_table.end(); it2++){
                    if(it2->second->getActive() && it2->second->getIdent() == ident && it2->second->getScope() == currscope){ // Skip the inactive symbols and the symbols that don't match the ident. 
                        return (it2->second);
                    }  
                }
                --currscope;            
            }
            return NULL;
        }

        Symbol* lookup(string id, int scope, stack<bool> blockStack) {
            Symbol* searched = lookup(id, scope); // Search for a symbol with id.
            if (searched == NULL){
                return NULL;    // It doesn't exist.
            }
            
            int current_Scope = scope;

            if ( !blockStack.empty() ) {
                bool isFunctionBlock = blockStack.top();
                blockStack.pop();
                while (!blockStack.empty() && isFunctionBlock != true) {  // Calculate the minimum scope that we can access.
                    --current_Scope;
                    isFunctionBlock = blockStack.top();
                    blockStack.pop();
                }
            }

            if (searched->getScope() < current_Scope && searched->getType() != USER_FUNCTION && searched->getScope() != 0 && searched->getType() != LIBRARY_FUNCTION){
                return ( new Symbol(__ERROR__, " $is error$ ", 0, 0, false) );  // We don't have access to the variable.
            }else{ 
                return searched; // We have access return the variable.
            } 
        }

        

        void hide(unsigned int currScope){
            if (currScope == 0){
                return;
            }

            for (auto it = map_table.begin(); it != map_table.end(); it++) {
                if(it->second->getScope() == currScope ){
                    (*it).second->setActive(false);
                }
            }
        }

        void printSymTable() {
            for(int i = 0; i <= get_max_scope(); i++) {
                cout << "----------------- Scope #" << i << "-----------------" << endl;
                vector<Symbol*> symVector;
                // Step 1: Collect symbols of the given scope
                for (auto it = map_table.begin(); it != map_table.end(); ++it) {
                    if(it->second->getScope() == i) {
                        symVector.push_back(it->second);
                    }
                }
                // Step 2: Sort the collected symbols by lineno
                sort(symVector.begin(), symVector.end(), [](Symbol* a, Symbol* b) {
                    return a->getLineno() < b->getLineno();
                });
                // Step 3: Print the sorted symbols
                for (auto sym : symVector) {
                    cout << "\"" << sym->getIdent() << "\" " 
                        << "[" << state_str[sym->getType()] << "] "
                        << "(Line " << sym->getLineno() << ") "
                        << "(Scope " << sym->getScope() << ") "
                        << endl;
                }
                cout << endl;
            }
        }

        bool contains(string ident , symbol_T type){
            auto it = map_table.find(ident);
            while (it != map_table.end()) {
                if (it->second->getIdent() == ident && it->second->getType() == type && it->second->getActive() ){
                    return true;
                } 
                it++;
            }
            return false;
        }

        bool contains(string ident , unsigned int scope){
            auto it = map_table.find(ident);
            while (it != map_table.end()) {
                if (it->second->getIdent() == ident &&  it->second->getScope() == scope && it->second->getActive() ) {
                    return true;
                } 
                it++;
            }
            return false;
        }


        Symbol* get(string ident,unsigned int scope){  
            auto it = map_table.find(ident);      

            if(it == map_table.end()){
                return NULL;
            }

            if (it->second->getScope() != scope) {
                return NULL;
            }
        
            return it->second;
        }

        // list<Symbol*> getSymbolesFromScope(unsigned int scope){
        //     list<Symbol*> list;
        //     for (auto it = map_table.begin(); it != map_table.end(); it++) {
        //         if(it->second->getScope() == scope){
        //             list.push_back(it->second);
        //         }
        //     }
        //     return list;
        // }

};
#endif

