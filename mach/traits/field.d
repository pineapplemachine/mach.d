module mach.traits.field;

private:

import std.meta : staticIndexOf;
import std.traits : FieldNameTuple, Unqual;

public:



enum hasField(T, string field) = staticIndexOf!(field, FieldNameTuple!T) >= 0;

template hasProperty(T, string property){
    enum bool hasProperty = is(typeof((inout int = 0){
        mixin(`auto property = T.init.` ~ property ~ `;`);
    }));
}



version(unittest){
    private:
    struct TestField{
        int x, y;
        @property int z() const{
            return this.x + this.y;
        }
    }
}
unittest{
    // hasField
    static assert(hasField!(TestField, `x`));
    static assert(hasField!(TestField, `y`));
    static assert(!hasField!(TestField, `z`));
    static assert(!hasField!(TestField, `w`));
    // hasProperty
    static assert(hasProperty!(TestField, `x`));
    static assert(hasProperty!(TestField, `y`));
    static assert(hasProperty!(TestField, `z`));
    static assert(!hasProperty!(TestField, `w`));
}
