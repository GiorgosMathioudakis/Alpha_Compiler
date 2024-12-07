#include <string.h>
#include <string>
#include <stack>
#include <algorithm>

#include "symbol_Table.hpp"
#include "intermediate_code.hpp"

extern std::vector<Quad*> Quads;

typedef enum vmopcode {
    assign_v, 
    add_v, 
    sub_v, 
    mul_v, 
    div_v, 
    mod_v, 
    uminus_v, 
    and_v, 
    or_v, 
    not_v,
    if_eq_v,
    if_noteq_v,
    if_lesseq_v,
    if_greatereq_v,
    if_less_v,
    if_greater_v, 
    call_v, 
    push_v,
    pusharg_v, 
    funcenter_v,
    funcexit_v, 
    newtable_v, 
    tablegetelem_v, 
    tablesetelem_v, 
    nop_v, 
    jump_v
} vmopcode;

const char* VMopToString(vmopcode op) {
    switch (op) {
    case assign_v:
        return "assign";
    case add_v:
        return "add";
    case sub_v:
        return "sub";
    case mul_v:
        return "mul";
    case div_v:
        return "div";
    case mod_v:
        return "mod";
    case and_v:
        return "and";
    case or_v:
        return "or";
    case not_v:
        return "not";
    case if_eq_v:
        return "if_eq";
    case if_noteq_v:
        return "if_noteq";
    case if_lesseq_v:
        return "if_lesseq";
    case if_greatereq_v:
        return "if_greatereq";
    case if_less_v:
        return "if_less";
    case if_greater_v:
        return "if_greater";
    case call_v:
        return "call";
    case pusharg_v:
        return "pusharg";
    case funcenter_v:
        return "enterfunc";
    case funcexit_v:
        return "exitfunc";
    case newtable_v:
        return "tablecreate";
    case tablegetelem_v:
        return "tablegetelem";
    case tablesetelem_v:
        return "tablesetelem";
    case jump_v:
        return "jump";
    default:
        assert(0);
    }
}

typedef enum vmarg_t {
    label_a,
    global_a,
    formal_a,
    local_a,
    number_a,
    string_a,
    bool_a,
    nil_a,
    userfunc_a,
    libfunc_a,
    retval_a,
    undefined_a,
} vmarg_t;

std::string VMtypeToString(vmarg_t type) {
    switch (type) {
    case label_a:
        return "label";
    case global_a:
        return "global";
    case formal_a:
        return "formal";
    case local_a:
        return "local";
    case number_a:
        return "number";
    case string_a:
        return "string";
    case bool_a:
        return "bool";
    case nil_a:
        return "nil";
    case userfunc_a:
        return "userfunc";
    case libfunc_a:
        return "libfunc";
    case retval_a:
        return "retval";
    case undefined_a:
        return "undefined";
    default:
        assert(0);
    }
}

typedef struct vmarg { 
    vmarg_t type;  //offset in the stack
    unsigned int val; //actuall value

    std::string to_string() {
        if (this->type == undefined_a)
            return "";
        if (this->type == retval_a)
            return std::to_string(this->type) + "(" + VMtypeToString(this->type) + ")";
        else
            return std::to_string(this->type) + "(" + VMtypeToString(this->type) + ")," + std::to_string(this->val);
    }

} vmarg ;

class instruction {
    public:
        vmopcode opcode;
        vmarg result;
        vmarg arg1;
        vmarg arg2;
        unsigned srcLine;

    instruction() {

        opcode = nop_v;
        result.type = undefined_a;
        result.val = 0;
        arg1.type = undefined_a;
        arg1.val = 0;
        arg2.type = undefined_a; 
        arg2.val = 0;
    
    }
};

vector<instruction> instructions{};
vector<double> const_numb{};
vector<std::string> const_str{};
vector<Symbol*> userfuncs{};
vector<std::string> libfuncs{};

int nextinstructionlabel(){
    return Quads.size();
}

void reset_operand(vmarg* arg){
    arg->type = nil_a;
}

void make_booloperand(vmarg* arg, unsigned val){
    arg->val = val;
    arg->type = bool_a;
}

void make_retvaloperand(vmarg* arg){
    arg->type = retval_a;
}
//lympe
unsigned int const_newstring(string s){
    auto it = find(const_str.begin(), const_str.end(), s);
    if (it == const_str.end()) {
        const_str.push_back(s);
        return const_str.size() - 1;
    }
    else {
        return it - const_str.begin();
    }
}
//lympe
unsigned int const_newnumber(double s){
    auto it = find(const_numb.begin(), const_numb.end(), s);
    if (it == const_numb.end()) {
        const_numb.push_back(s);
        return const_numb.size() - 1;
    }
    else {
        return it - const_numb.begin();
    }
}
//lympe
unsigned int library_newused(string s) {
    auto it = std::find(libfuncs.begin(), libfuncs.end(), s);
    if (it == libfuncs.end()) {
        libfuncs.push_back(s);
        return libfuncs.size() - 1;
    }
    else {
        return it - libfuncs.begin();
    }
}
//lympe
unsigned int userfuncs_newfunc(Symbol* sym) {
                //OUSIASTIKA PREPEI NA VLEPEI AN IPARXEI I SINARTISI GIRNA TO INDEX STO VECTOR POU VRISKETAI
                //AN OXI PUSH BACK STHN LISTA KAI EPESTREPSE TO INDEX
    for (auto it=userfuncs.begin();it != userfuncs.end();++it){
        if((*it)->getIdent() == sym->getIdent() && (*it)->getAddress_T() == sym->getAddress_T()){
            return it - userfuncs.begin();
        }else{
           userfuncs.push_back(sym);
            return userfuncs.size() - 1; 
        }
        
    }

    return 0;
}

vmarg make_operand(Expr* e) {
    vmarg temp{};

    if (!e) {
        temp.type = undefined_a;
        temp.val = 0;
        return temp;
    }

    switch (e->type) {
    case ASSIGNEXPR_E:
    case VAR_E:
    case TABLEITEM_E:
    case ARITHMEXPR_E:
    case BOOLEXPR_E:
    case NEWTABLE_E:
        assert(e->sym);

        temp.val = e->sym->getOffset();

        switch (e->sym->getSpace()) {
        case PROGRAM_VAR:
            temp.type = global_a;
            break;
        case FUNCTION_LOCAL:
            temp.type = local_a;
            break;
        case FORMAL_ARG:
            temp.type = formal_a;
            break;
        default:
            assert(0);
        }
        break;
    case CONSTBOOL_E:
        temp.val = std::get<bool>(e->value);
        temp.type = bool_a;
        break;
    case CONSTSTRING_E:
        temp.val = const_newstring(std::get<std::string>(e->value));
        temp.type = string_a;
        break;
    case CONSTNUM_E:
        temp.val = const_newnumber(std::get<double>(e->value));
        temp.type = number_a;
        break;
    case NIL_E:
        temp.type = nil_a;
        break;
    case PROGRAMFUNC_E:
        temp.type = userfunc_a;
        temp.val = userfuncs_newfunc(e->sym);
        break;
    case LIBRARYFUNC_E:
        temp.type = libfunc_a;
        temp.val = library_newused(e->sym->getIdent());
        break;
    default:
        assert(0);
    }

    return temp;
}   

void emit_t(instruction instr){
    instructions.push_back(instr);
   
}
void generate(vmopcode op, Quad* quad){
    instruction t;
    t.srcLine = quad->line;
    t.opcode = op;
    t.arg1 = make_operand(quad -> arg1);
    t.arg2 = make_operand(quad -> arg2);

    if((op >= if_eq_v && op <= if_greater_v)){
        t.result.type = label_a; 
        t.result.val = quad->label;
    }else{
        t.result = make_operand(quad->result);
    }

    emit_t(t);
}

void generate_ADD(Quad* quad){
    generate(add_v, quad);
}

void generate_SUB(Quad* quad){
    generate(sub_v, quad);
}

void generate_MUL(Quad* quad){
    generate(mul_v, quad);
}

void generate_DIV(Quad* quad){
    generate(div_v, quad);
}

void generate_MOD(Quad* quad){
    generate(mod_v, quad);
}

void generate_NEWTABLE(Quad* quad){
    generate(newtable_v, quad);
}

void generate_TABLEGETELEM(Quad* quad){
    generate(tablegetelem_v, quad);
}

void generate_TABLESETELEM(Quad* quad){
    generate(tablesetelem_v, quad);
}

void generate_ASSIGN(Quad* quad){
    generate(assign_v, quad);
}

void generate_NOP(Quad* q){
    instruction t;
    t.opcode = nop_v;
    emit_t(t);
}

// void generate_relational(vmopcode op, Quad* quad){
//     instruction t;
//     t.opcode = op;
//     make_operand(quad -> arg1, &t.arg1);
//     make_operand(quad -> arg2, &t.arg2);
//     t.result.type = label_a;

//     if (quad -> label < nextinstructionlabel()){
//         t.result.val = quad[quad -> label].taddress;
//     } else {
//         add_incomplete_jump(nextinstructionlabel(), quad -> label);
//     }
//     quad -> taddress = nextinstructionlabel();
//     emit_t(t);
// }

void generate_JUMP(Quad* quad){
    instruction t;
    t.srcLine = quad->line;
    t.opcode = jump_v;
    t.result.type = label_a;
    t.result.val = quad->label;
    emit_t(t);
}

void generate_IF_EQ(Quad* quad){
    generate(if_eq_v, quad);
}

void generate_IF_NOTEQ(Quad* quad){
    generate(if_noteq_v, quad);
}

void generate_IF_GREATER(Quad* quad){
    generate(if_greater_v, quad);
}

void generate_IF_GREATEREQ(Quad* quad){
    generate(if_greatereq_v, quad);
}

void generate_IF_LESS(Quad* quad){
    generate(if_less_v, quad);
}

void generate_IF_LESSEQ(Quad* quad){
    generate(if_lesseq_v, quad);
}

void generate_UMINUS(Quad* quad) {
    generate(mul_v, quad);
}

// void generate_NOT(Quad* quad){
//     quad->taddress = nextinstructionlabel();
//     instruction t;
//     t.opcode = jeq_v;
//     make_operand(quad -> arg1, &t.arg1);
//     make_booloperand(&t.arg2, 0);
//     t.result.type = label_a;
//     t.result.val = nextinstructionlabel() + 3;
//     emit_t(t);

//     t.opcode = assign_v;
//     make_booloperand(&t.arg1, 0);
//     reset_operand(&t.arg2);
//     make_operand(quad -> result, &t.result);
//     emit_t(t);

//     t.opcode = jump_v;
//     reset_operand(&t.arg1);
//     reset_operand(&t.arg2);
//     t.result.type = label_a;
//     t.result.val = nextinstructionlabel() + 2;
//     emit_t(t);

//     t.opcode = assign_v;
//     make_booloperand(&t.arg1, 1);
//     reset_operand(&t.arg2);
//     make_operand(quad -> result, &t.result);
//     emit_t(t);
// }
void generate_NOT(Quad* quad){
    generate(not_v,quad);
}
void generate_OR(Quad* quad){
    generate(or_v,quad);

}
void generate_AND(Quad* quad){
    generate(and_v,quad);
}



// void generate_OR(Quad* quad){
//     quad->taddress = nextinstructionlabel();
//     instruction t;
//     t.opcode = jeq_v;
//     make_operand(quad -> arg1, &t.arg1);
//     make_booloperand(&t.arg2, 1);
//     t.result.type = label_a;
//     t.result.val = nextinstructionlabel() + 4;
//     emit_t(t);

//     t.opcode = jeq_v;
//     make_operand(quad -> arg2, &t.arg1);
//     t.result.val = nextinstructionlabel() + 3;
//     emit_t(t);

//     t.opcode = assign_v;
//     make_booloperand(&t.arg1, 0);
//     reset_operand(&t.arg2);
//     make_operand(quad -> result, &t.result);
//     emit_t(t);

//     t.opcode = jump_v;
//     reset_operand(&t.arg1);
//     reset_operand(&t.arg2);
//     t.result.type = label_a;
//     t.result.val = nextinstructionlabel() + 2;
//     emit_t(t);

//     t.opcode = assign_v;
//     make_booloperand(&t.arg1, 1);
//     reset_operand(&t.arg2);
//     make_operand(quad -> result, &t.result);
//     emit_t(t);
// }

void generate_PARAM(Quad* quad){
    // quad -> taddress = nextinstructionlabel();
    // instruction t;
    // t.opcode = pusharg_v;
    // make_operand(quad -> arg1, &t.arg1);
    // emit_t(t);
    instruction t{};
    t.srcLine = quad->line;
    t.opcode = pusharg_v;
    t.arg1 = make_operand(quad->arg1);
    emit_t(t);
}

void generate_CALL(Quad* quad){
    //quad -> taddress = nextinstructionlabel();
    instruction t;
    t.srcLine = quad->line;
    t.opcode = call_v;
    //make_operand(quad -> result, &t.result);
    t.arg1 = make_operand(quad->arg1);
    emit_t(t);
}

void generate_GETRETVAL(Quad* quad){
    // quad -> taddress = nextinstructionlabel();
    // instruction t;
    // t.opcode = assign_v;
    // make_operand(quad -> result, &t.result);
    // make_retvaloperand(&t.arg1);
    // emit_t(t);
    instruction t;
    t.srcLine = quad->line;
    t.opcode = assign_v;
    t.result = make_operand(quad->result);
    make_retvaloperand(&t.arg1);
    emit_t(t);
}

void generate_FUNCSTART(Quad* quad){
    // quad -> taddress = nextinstructionlabel();
    // quad->arg1->sym->setAddress(quad->taddress);
    // instruction t;
    // t.opcode = funcenter_v;
    // make_operand(quad -> result, &t.result);
    // emit_t(t);
    cout << " 3ekinaw func" << endl;
    instruction t{};
    t.srcLine = quad->line;
    t.opcode = funcenter_v;
    t.result = make_operand(quad->arg1);
    emit_t(t);
}

void generate_RETURN(Quad* quad){
    // quad -> taddress = nextinstructionlabel();
    // instruction t;
    // t.opcode = assign_v;
    // make_retvaloperand(&t.result);
    // make_operand(quad -> result, &t.arg1);
    // emit_t(t);
    instruction t;
    t.opcode = assign_v;
    make_retvaloperand(&t.result);
    t.arg1 = make_operand(quad->arg1);
    emit_t(t);
}

void generate_FUNCEND(Quad* quad){
    // quad -> taddress = nextinstructionlabel();
    // instruction t;
    // //yapping edw 
    // t.opcode = funcexit_v;
    // make_operand(quad -> result, &t.result);
    // emit_t(t);
    instruction t;
    t.opcode = funcexit_v;
    t.result = make_operand(quad->result);
    emit_t(t);
}

typedef void (*generator_func_t)(Quad*);

generator_func_t generators[] = {
    generate_ASSIGN,
    generate_ADD,
    generate_SUB,
    generate_MUL,
    generate_DIV,
    generate_MOD,
    generate_UMINUS,
    generate_AND,
    generate_OR,
    generate_NOT,
    generate_IF_EQ,
    generate_IF_NOTEQ,
    generate_IF_LESSEQ,
    generate_IF_GREATEREQ,
    generate_IF_LESS,
    generate_IF_GREATER,
    generate_CALL,
    generate_PARAM,
    generate_RETURN,
    generate_GETRETVAL,
    generate_FUNCSTART,
    generate_FUNCEND,
    generate_NEWTABLE,
    generate_TABLEGETELEM,
    generate_TABLESETELEM,
    generate_JUMP,
    generate_NOP
};

void generate_all(void) {
    for (unsigned int i = 0; i < Quads.size(); i++) {
        (*generators[Quads[i]->op]) (Quads[i]);
    }
}

string remove_extra_zero(std::string number) {
    if (number.find(".") == std::string::npos)
        return number;
    reverse(number.begin(), number.end());
    int i;
    for (i = 0; i < number.size(); i++) {
        if (number[i] != '0') break;
    }
    number = number.substr(i, number.size());
    reverse(number.begin(), number.end());
    return number;
}

string modify_number(double number) {
    if (floor(number) == ceil(number))
        return std::to_string((int)number);
    else return std::to_string(number);
}

void printTargetCode(std::string filename) {
    FILE* file;
    if (filename == "") file = stdout;
    else file = fopen(std::string(filename + ".tc").c_str(), "wb");

    if (!file) {
        printf("File cannot open.\n");
        return;
    }
    fprintf(file, "Instruction#\t\tOpcode\t\tResult\t\tArg1\t\tArg2\n");
    fprintf(file, "===================================================================================\n");

    for (int i = 0; i < instructions.size(); i++) {

        instruction curr = instructions[i];

        fprintf(file, "%d:\t\t\t%s\t\t%s\t%s\t%s\n",
            i + 1,
            VMopToString(curr.opcode),
            curr.result.to_string() == "" ? "\t\t" : curr.result.to_string().c_str(),
            curr.arg1.to_string() == "" ? "\t\t" : curr.arg1.to_string().c_str(),
            curr.arg2.to_string() == "" ? "\t\t" : curr.arg2.to_string().c_str()
        );
    }
    fprintf(file, "===================================================================================\n");

    if (!const_numb.empty()) {
        fprintf(file, "\nConst Numbers:\n");
        fprintf(file, "===================================================================================\n");
        for (int i = 0; i < const_numb.size(); ++i)
            fprintf(file, "%d:\t%s\n", i, remove_extra_zero(modify_number(const_numb[i])).c_str());
        fprintf(file, "===================================================================================\n");
    }

    if (!const_str.empty()) {
        fprintf(file, "\nConst Strings:\n");
        fprintf(file, "===================================================================================\n");
        for (int i = 0; i < const_str.size(); ++i)
            fprintf(file, "%d:\t%s\n", i, const_str[i].c_str());
        fprintf(file, "===================================================================================\n");
    }

    if (!userfuncs.empty()) {
        fprintf(file, "\nUser Functions:\n");
        fprintf(file, "===================================================================================\n");
        for (int i = 0; i < userfuncs.size(); ++i)
            fprintf(file, "%d:\t%s\n", i, userfuncs[i]->getIdent().c_str());
        fprintf(file, "===================================================================================\n");
    }

    if (!libfuncs.empty()) {
        fprintf(file, "\nLibrary Functions:\n");
        fprintf(file, "===================================================================================\n");
        for (int i = 0; i < libfuncs.size(); ++i)
            fprintf(file, "%d:\t%s\n", i, libfuncs[i].c_str());
        fprintf(file, "===================================================================================\n");
    }
}



void printTargetInBinary(std::string filename) {
    FILE* file;
    if (filename == "") file = stdout;
    else file = fopen(std::string(filename + ".ab").c_str(), "wb");

    unsigned int magicNumber = 340200501;
    fwrite(&magicNumber, sizeof(magicNumber), 1, file);

    if (!const_str.empty()) {
        unsigned int size = const_str.size();
        fwrite(&size, sizeof(size), 1, file);
        for (int i = 0; i < size; ++i) {
            const char* string = const_str[i].c_str();
            fwrite(string, sizeof(char), strlen(string) + 1, file);
        }
    }
    else {
        unsigned int size = 0;
        fwrite(&size, sizeof(size), 1, file);
    }

    if (!const_numb.empty()) {
        unsigned int size = const_numb.size();
        fwrite(&size, sizeof(size), 1, file);
        for (int i = 0; i < size; ++i) {
            double num = const_numb[i];
            fwrite(&num, sizeof(double), 1, file);
        }
    }
    else {
        unsigned int size = 0;
        fwrite(&size, sizeof(size), 1, file);
    }

    if (!userfuncs.empty()) {
        unsigned int size = userfuncs.size();
        fwrite(&size, sizeof(size), 1, file);
        for (int i = 0; i < size; ++i) {
            unsigned int address = userfuncs[i]->getAddress_T();
            unsigned int localsize = userfuncs[i]->getTotalLocals();
            const char* id = userfuncs[i]->getIdent().c_str();
            fwrite(&address, sizeof(unsigned int), 1, file);
            fwrite(&localsize, sizeof(unsigned int), 1, file);
            fwrite(id, sizeof(char), strlen(id) + 1, file);
        }
    }
    else {
        unsigned int size = 0;
        fwrite(&size, sizeof(size), 1, file);
    }

    if (!libfuncs.empty()) {
        unsigned int size = libfuncs.size();
        fwrite(&size, sizeof(size), 1, file);
        for (int i = 0; i < size; ++i) {
            const char* id = libfuncs[i].c_str();
            fwrite(id, sizeof(char), strlen(id) + 1, file);
        }
    }
    else {
        unsigned int size = 0;
        fwrite(&size, sizeof(size), 1, file);
    }

    if (!instructions.empty()) {
        unsigned int size = instructions.size();
        fwrite(&size, sizeof(size), 1, file);
        for (int i = 0; i < size; ++i) {
            char* opcode = (char*)&(instructions[i].opcode);
            const char* result_type = (char*)&(instructions[i].result.type);
            unsigned int result_val = instructions[i].result.val;
            const char* arg1_type = (char*)&(instructions[i].arg1.type);
            unsigned int arg1_val = instructions[i].arg1.val;
            const char* arg2_type = (char*)&(instructions[i].arg2.type);
            unsigned int arg2_val = instructions[i].arg2.val;
            unsigned int srcLine = instructions[i].srcLine;
            fwrite(opcode, sizeof(char), 1, file);

            fwrite(result_type, sizeof(char), 1, file);
            fwrite(&result_val, sizeof(unsigned int), 1, file);

            fwrite(arg1_type, sizeof(char), 1, file);
            fwrite(&arg1_val, sizeof(unsigned int), 1, file);

            fwrite(arg2_type, sizeof(char), 1, file);
            fwrite(&arg2_val, sizeof(unsigned int), 1, file);

            fwrite(&srcLine, sizeof(unsigned int), 1, file);
        }
    }
    else {
        unsigned int size = 0;
        fwrite(&size, sizeof(size), 1, file);
    }
    return;
}