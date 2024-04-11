    /* Definitions */
%{
    #include <iostream>
    #include <string>
    #include <stack>
    #include "parser.hpp" 
    #include "symbol_Table.hpp"
    
    using namespace std;

    /* Global variables */
    enum state { DEFAULT = 0 , LINE_COMMENT = 1 , BLOCK_COMMENT = 2 } state = DEFAULT ; 
    std::stack<unsigned int> commentStack;
    
    // redefintion of a string based on special chars
    char* redefString(char* str){
        int j = 0;
        int strsize = strlen(str);
        char* redefString = new char[strsize + 1];
        for(int i = 0; i < strsize; ++i) {
            if(str[i] != '\\') redefString[j++] = str[i];
            else {
                switch(str[i + 1]) {
                    case 'n':
                        redefString[j++] = '\n';
                        i++;
                        break;
                    case 't':
                        redefString[j++] = '\t';
                        i++;
                        break;
                    case '\\':
                        redefString[j++] = '\\';
                        i++;
                        break;
                    case '\"':    
                        redefString[j++] = '"';
                        i++;
                        break;    
                    default:
                        perror("Invalid escape character found!");
                        return NULL;
                }
            }
        }
        return redefString;
    }
%}

    /* Flex options */
%option yylineno
%option noyywrap 


    /* ___Flex macros___ */
    /* KEYWORDS */
IF                          "if"
ELSE                        "else"
WHILE                       "while"
FOR                         "for"
FUNCTION                    "function"
RETURN                      "return"
BREAK                       "break"
CONTINUE                    "continue"
AND                         "and"
NOT                         "not"
OR                          "or"
LOCAL                       "local"
TRUE                        "true"
FALSE                       "false"
NIL                         "nil"

    /* OPERATORS */
ASSIGNMENT                  "="
PLUS                        "+"
MINUS                       "-"
MULTIPLY                    "*"
DIVIDE                      "/"
MODULUS                     "%"
INCREMENT                   "++"
DECREMENT                   "--"
LESS_THAN                   "<"
GREATER_THAN                ">"
LESS_THAN_OR_EQUAL          "<="
GREATER_THAN_OR_EQUAL       ">="
EQUAL                       "=="
NOT_EQUAL                   "!="

    /* PANCTUATION */
LEFT_CURLY_BRACKET          "{"
RIGHT_CURLY_BRACKET         "}"
PERIOD                      "."
COMMA                       ","
COLON                       ":"
SEMICOLON                   ";"
RIGHT_BRACKET               "]"
LEFT_BRACKET                "["
RIGHT_PARENTHESIS           ")"
LEFT_PARENTHESIS            "("
DOUBLE_COLON                "::"
DOUBLE_PERIOD               ".." 
LINE_COMMENT                "//"
BLOCK_COMMENT_OPEN          "/*"
BLOCK_COMMENT_CLOSE         "*/"

    /* REGEX */
id                  [a-zA-Z][a-zA-Z_0-9]*
integer             (0[xX][0-9A-Fa-f]+)|([0-9]+)
real                [0-9]*\.[0-9](e|E)?[0-9]*
space               [\r\n \t\v]
string              \"(\\.|[^"\\])*\" 
INCOMPLETE_STRING   \"


    /* PATTERN ACTIONS */
%%
    
{BLOCK_COMMENT_OPEN}    {
    if(state != LINE_COMMENT){
        state = BLOCK_COMMENT; 
        commentStack.push(yylineno);
    }
}

{BLOCK_COMMENT_CLOSE}    {
    if(state!=LINE_COMMENT) {
        if( commentStack.empty() )    return (ERROR);
        commentStack.pop();
        if( commentStack.empty() )    state = DEFAULT ; 
    }
}

{INCOMPLETE_STRING} {
    if(state != DEFAULT){
      return (ERROR);  
    }
}

{LINE_COMMENT}  {
    if( state == BLOCK_COMMENT ) unput(yytext[1]);
    else if( state == DEFAULT ) state = LINE_COMMENT ; 
}

{LEFT_CURLY_BRACKET}   {
    if(state == DEFAULT) 
        return (LEFT_CURLY_BRACKET);
}

{RIGHT_CURLY_BRACKET}  {
    if(state == DEFAULT) 
        return (RIGHT_CURLY_BRACKET);
}

{PERIOD}   {

    if(state == DEFAULT) 
        return (PERIOD);
        
}

{COMMA} {

    if(state == DEFAULT) 
        return (COMMA);
}

{COLON} {
    if(state == DEFAULT) 
        return (COLON);
}

{SEMICOLON} {
    if(state == DEFAULT) 
        return (SEMICOLON);
}

{RIGHT_BRACKET} {
    if(state == DEFAULT) 
        return (RIGHT_BRACKET);
}

{LEFT_BRACKET}  {
    if(state == DEFAULT) 
        return (LEFT_BRACKET);
}

{RIGHT_PARENTHESIS} {
    if(state == DEFAULT) 
        return (RIGHT_PARENTHESIS);
}

{LEFT_PARENTHESIS}  {

    if(state == DEFAULT) 
        return (LEFT_PARENTHESIS);
}

{DOUBLE_COLON}    {
    if(state == DEFAULT) 
        return (DOUBLE_COLON);
}

{DOUBLE_PERIOD}   {
    if(state == DEFAULT)
        return (DOUBLE_PERIOD);
}

{IF}    {
    if(state == DEFAULT) 
        return (IF);
}

{ELSE}  {
    if(state == DEFAULT) {
        return (ELSE);
    }
}

{WHILE} {
    if(state == DEFAULT) {
        return (WHILE);
    }
}

{FOR}   {
    if(state == DEFAULT) {
        return (FOR);
    }
}

{FUNCTION} {
    if(state == DEFAULT) {
        return (FUNCTION);
    }
}

{RETURN} {
    if(state == DEFAULT) {
        return (RETURN);
    }
}

{BREAK} {
    if(state == DEFAULT) {
        return (BREAK);
    }
}

{CONTINUE} {
    if(state == DEFAULT) {
        return (CONTINUE);
    }
}

{AND} {
    if(state == DEFAULT) {
        return (AND);
    }
}

{NOT}   {
    if(state == DEFAULT) {
        return (NOT);
    }
}

{OR}    {
    if(state == DEFAULT) {
        return (OR);
    }
}

{LOCAL} {
    if(state == DEFAULT) {
        return (LOCAL);
    }
}

{TRUE}  {
    if(state == DEFAULT) {
        return (TRUE);
    }
}

{FALSE} {
    if(state == DEFAULT) {
        return (FALSE);
    }
}

{NIL}   {
    if(state == DEFAULT) {
        return (NIL);
    }
}

{ASSIGNMENT} {
    if(state == DEFAULT) {
        return (ASSIGNMENT);
    }
}

{PLUS}  {
    if(state == DEFAULT) {
        return (PLUS);
    }
}

{MINUS} {
    if(state == DEFAULT) {
        return (MINUS);
    }
}

{MULTIPLY}  {
    if(state == DEFAULT) {
        return (MULTIPLY);
    }
}

{DIVIDE}    {
    if(state == DEFAULT) {
        return (DIVIDE);
    }
}

{MODULUS}   {
    if(state == DEFAULT) {
        return (MODULUS);
    }
}

{INCREMENT} {    
    if(state == DEFAULT) {
        return (INCREMENT);
    }
}

{DECREMENT} {
    if(state == DEFAULT) {
        return (DECREMENT);
    }
}

{LESS_THAN} {
    if(state == DEFAULT) {
        return (LESS_THAN);
    }
}

{GREATER_THAN}  {
    if(state == DEFAULT) {
        return (GREATER_THAN);
    }
}

{LESS_THAN_OR_EQUAL}    {
    if(state == DEFAULT) {
        return (LESS_THAN_OR_EQUAL);
    }
}

{GREATER_THAN_OR_EQUAL} {
    if(state == DEFAULT) {
        return (GREATER_THAN_OR_EQUAL);
    }
}

{EQUAL} {
    if(state == DEFAULT) {
        return (EQUAL);
    }
}

{NOT_EQUAL} {
    if(state == DEFAULT) {
        return (NOT_EQUAL);
    }
}


{id}    {
    if(state == DEFAULT) {
        yylval.string = yytext;
        return (ID);
    }
}

{integer}   {
    if(state == DEFAULT) {
        yylval.integer = atoi(yytext);
        return (INTEGER);
    }
}

{real}  {
    if(state == DEFAULT) {
        yylval.real = stod(yytext);
        return (REAL);
    }
}

{space} {
    if(strcmp(yytext,"\n") == 0 && state == LINE_COMMENT) {
        state = DEFAULT;
    }
}

{string}    {
    if(state == DEFAULT) {
        char* str = redefString(yytext);
        yylval.string = yytext;
        return (STRING);
    }
}

.   { 
    if(state == DEFAULT) {
        cout << "UNDEF INPUT: "<<yytext <<" AT LINE: "<<yylineno<<endl; 
        return (ERROR);
    }
    
}
%%