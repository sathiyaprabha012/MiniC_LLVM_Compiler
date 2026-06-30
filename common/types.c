#include "types.h"

const char *data_type_to_string(DataType type) {
    switch (type) {
        case TYPE_INT:     return "int";
        case TYPE_FLOAT:   return "float";
        case TYPE_CHAR:    return "char";
        case TYPE_BOOL:    return "bool";
        case TYPE_VOID:    return "void";
        case TYPE_UNKNOWN: return "unknown";
        default:           return "invalid";
    }
}
