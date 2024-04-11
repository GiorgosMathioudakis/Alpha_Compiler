    /* Definitions */
%{
    #include <queue>
    #include <iostream>
    #include <string>
    #include <stack>
    #include <string.h>
    using namespace std;

    #define YY_DECL int alpha_yylex(void* yylval)

    typedef struct node {
        unsigned int numline;
        unsigned int numtoken;
        string content;
        string tok_category;
        string tok_type;
        string content_type;
    }alpha_token_t;  

     
    /* Global variables */
    enum state { DEFAULT = 0 , LINE_COMMENT = 1 , BLOCK_COMMENT = 2 } state ; 
    unsigned int tokenCounter;
    std::queue<alpha_token_t> tokenQueue;
    std::stack<unsigned int> commentStack;
    

    void insertToken(string content , string category , string tok_type , string content_type);

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
%option outfile="scanner.cpp"  

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

        string content = "";
        unsigned int end_lineno = yylineno;
        
        if(!commentStack.empty()){
            alpha_token_t token;
            token.numtoken = ++tokenCounter;
            content += to_string(commentStack.top()) + " - " + to_string(end_lineno);
            token.content = content;
            token.numline = commentStack.top();
            if(commentStack.size() > 1){
                token.tok_category = "NESTED_COMMENT";
            }else{
                token.tok_category = "COMMENT";
            }
            token.tok_type = "BLOCK_COMMENT";
            token.content_type = "enumerated";
            tokenQueue.push(token);
            commentStack.pop();
        }
        else{
            // THERE IS NO OPENING BLOCK COMMENT SO WE ADD TOKENS * AND / 
            insertToken("*" , "OPERATOR" , "MULTIPLY" , "enumerated");
            insertToken("/" , "OPERATOR" , "DEVIDE" , "enumerated");
        }
        

        if(commentStack.empty()){
            state = DEFAULT;
        }else{
            state = BLOCK_COMMENT;
        }
    }
}

{INCOMPLETE_STRING} {
    if(state != DEFAULT) return 0;
    std::cerr << "Error: Incomplete string was detected at line: " << yylineno << std::endl;
}

{LINE_COMMENT}  {
    if(state==DEFAULT){
        insertToken( "" , "COMMENT" , "LINE_COMMENT" , "enumerated");
        state = LINE_COMMENT;
    }
    if( state == BLOCK_COMMENT ) unput(yytext[1]);

}

{LEFT_CURLY_BRACKET}   {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "LEFT_CURLY_BRACKET" , "enumerated");
    }
}

{RIGHT_CURLY_BRACKET}  {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "RIGHT_CURLY_BRACKET" , "enumerated");
    }
}

{PERIOD}   {

    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "PERIOD" , "enumerated");
    }
}

{COMMA} {

    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "COMMA" , "enumerated");
    }
}

{COLON} {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "COLON" , "enumerated");
    }
}

{SEMICOLON} {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "SEMICOLON" , "enumerated");
    }
}

{RIGHT_BRACKET} {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "RIGHT_BRACKET" , "enumerated");
    }
}

{LEFT_BRACKET}  {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "LEFT_BRACKET" , "enumerated");
    }
}

{RIGHT_PARENTHESIS} {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "RIGHT_PARENTHESIS" , "enumerated");
    }
}

{LEFT_PARENTHESIS}  {

    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "LEFT_PARENTHESIS" , "enumerated");
    }
}

{DOUBLE_COLON}    {

    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "DOUBLE_COLON" , "enumerated");
    }
}

{DOUBLE_PERIOD}   {
    if(state == DEFAULT) {
        insertToken(yytext , "PANCTUATION" , "DOUBLE_PERIOD" , "enumerated");
    }
}

{IF}    {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYWORD" , "IF" , "enumerated");
    }
}

{ELSE}  {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYWORD" , "ELSE" , "enumerated");
    }
}

{WHILE} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "ELSE" , "enumerated");
    }
}

{FOR}   {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "FOR" , "enumerated");
    }
}

{FUNCTION} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "FUNCTION" , "enumerated");
    }
}

{RETURN} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "RETURN" , "enumerated");
    }
}

{BREAK} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "BREAK" , "enumerated");
    }
}

{CONTINUE} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "CONTINUE" , "enumerated");
    }
}

{AND} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "AND" , "enumerated");
    }
}

{NOT}   {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "NOT" , "enumerated");
    }
}

{OR}    {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "OR" , "enumerated");
    }
}

{LOCAL} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "LOCAL" , "enumerated");
    }
}

{TRUE}  {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "TRUE" , "enumerated");
    }
}

{FALSE} {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "FALSE" , "enumerated");
    }
}

{NIL}   {
    if(state == DEFAULT) {
        insertToken(yytext , "KEYOWRD" , "NIL" , "enumerated");
    }
}

{ASSIGNMENT} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "ASSIGNMENT" , "enumerated");
    }
}

{PLUS}  {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "PLUS" , "enumerated");
    }
}

{MINUS} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "MINUS" , "enumerated");
    }
}

{MULTIPLY}  {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "MULTIPLY" , "enumerated");
    }
}

{DIVIDE}    {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "DIVIDE" , "enumerated");
    }
}

{MODULUS}   {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "MODULUS" , "enumerated");
    }
}

{INCREMENT} {    
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "INCREMENT" , "enumerated");
    }
}

{DECREMENT} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "DECREMENT" , "enumerated");
    }
}

{LESS_THAN} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "LESS_THAN" , "enumerated");
    }
}

{GREATER_THAN}  {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "GREATER_THAN" , "enumerated");
    }
}

{LESS_THAN_OR_EQUAL}    {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "LESS_THAN_OR_EQUAL" , "enumerated");
    }
}

{GREATER_THAN_OR_EQUAL} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "GREATER_THAN_OR_EQUAL" , "enumerated");
    }
}

{EQUAL} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "EQUAL" , "enumerated");
    }
}

{NOT_EQUAL} {
    if(state == DEFAULT) {
        insertToken(yytext , "OPERATOR" , "NOT_EQUAL" , "enumerated");
    }
}


{id}    {
    if(state == DEFAULT) {
        insertToken(yytext , "IDENTIFIER" , yytext , "char* ");
    }
}

{integer}   {
    if(state == DEFAULT) {
        insertToken(yytext , "INTEGER" , yytext , "integer");
    }
}

{real}  {
    if(state == DEFAULT) {
        insertToken(yytext , "REAL" , yytext , "real");
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
        insertToken(str , "STRING" , str , "char*");
    }
}

.   { cout << "UNDEF INPUT: "<<yytext <<" AT LINE: "<<yylineno<<endl; 
    exit(0);
}

%%


void insertToken(string content ,string category , string tok_type , string content_type){
    alpha_token_t token ;
    token.numline = yylineno;
    token.numtoken = ++tokenCounter;
    token.content = content;
    token.tok_category = category;
    token.tok_type = tok_type;
    token.content_type = content_type;
    tokenQueue.push(token);
}


int main(int argc ,char** argv ){
    state = DEFAULT;
    tokenCounter = 0;
    tokenQueue = queue<alpha_token_t>(); 
    commentStack = stack<unsigned int>();


    if(argc > 1 ){
        if(!(yyin = fopen(argv[1],"r"))) {
            fprintf(stderr, "Cannot read file: %s\n" , argv[1]);    
            return 1;
        }
    }
    else{
        yyin = stdin;
    }

    alpha_yylex(&tokenQueue);

    // output 
    while(!tokenQueue.empty()){

        alpha_token_t token = tokenQueue.front();
        tokenQueue.pop();
        if(token.tok_category == "STRING"){
            cout << token.numline << ":\t#" << token.numtoken << "\t  " << token.content << "\t" << token.tok_category << "\t" <<token.tok_type << "\t<-"<<token.content_type << endl;
        }else{
            cout << token.numline << ":\t#" << token.numtoken << "\t  " << "\"" << token.content<< "\"" << "\t" << token.tok_category << "\t" <<token.tok_type << "\t<-"<<token.content_type << endl;
        }
    }
    
    if(yyin){
        if(!commentStack.empty()){
            cout << "COMMENT: " << "UNBALANCED COMMENT" << endl;
        }
    }
    
    fclose(yyin);
    return 0;
}
