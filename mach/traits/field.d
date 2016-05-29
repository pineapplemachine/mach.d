module mach.traits.field;

private:

import std.meta : staticIndexOf;
import std.traits : FieldNameTuple;

public:



// TODO: hasProperty

enum hasField(T, string field) = staticIndexOf!(field, FieldNameTuple!T) >= 0;

//template hasField(T, string field){
//    mixin(`enum bool hasField = is(typeof(T.` ~ field ~ `));`);
//}



version(unittest){
    private:
    struct TestField{
        int x, y;
    }
}
unittest{
    static assert(hasField!(TestField, `x`));
    static assert(hasField!(TestField, `y`));
    static assert(!hasField!(TestField, `z`));
}
