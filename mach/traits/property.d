module mach.traits.property;

private:

import std.meta : staticIndexOf;
import std.traits : FieldNameTuple, Unqual, isNumeric, isIntegral;

public:



enum hasField(T, string field) = staticIndexOf!(field, FieldNameTuple!T) >= 0;

template hasProperty(T, string property){
    enum bool hasProperty = is(typeof((inout int = 0){
        mixin(`auto property = T.init.` ~ property ~ `;`);
    }));
}

template hasProperty(alias pred, T, string property){
    static if(hasProperty!(T, property)){
        enum bool hasProperty = pred!(PropertyType!(T, property));
    }else{
        enum bool hasProperty = false;
    }
}

enum hasNumericProperty(T, string property) = (
    hasProperty!(isNumeric, T, property)
);

enum hasIntegralProperty(T, string property) = (
    hasProperty!(isIntegral, T, property)
);

template PropertyType(T, string property) if(hasProperty!(T, property)){
    mixin(`alias PropertyType = typeof(T.init.` ~ property ~ `);`);
}



version(unittest){
    private:
    struct TestField{
        int x;
        const int y;
        string str;
        @property int z() const{
            return this.x + this.y;
        }
    }
}
unittest{
    // hasField
    static assert(hasField!(TestField, `x`));
    static assert(hasField!(TestField, `y`));
    static assert(hasField!(TestField, `str`));
    static assert(!hasField!(TestField, `z`));
    static assert(!hasField!(TestField, `notaproperty`));
    // hasProperty
    static assert(hasProperty!(TestField, `x`));
    static assert(hasProperty!(TestField, `y`));
    static assert(hasProperty!(TestField, `z`));
    static assert(hasProperty!(TestField, `str`));
    static assert(!hasProperty!(TestField, `notaproperty`));
    // hasNumericProperty
    static assert(hasNumericProperty!(TestField, `x`));
    static assert(!hasNumericProperty!(TestField, `str`));
    static assert(!hasNumericProperty!(TestField, `notaproperty`));
    // hasIntegralProperty
    static assert(hasIntegralProperty!(TestField, `x`));
    static assert(!hasIntegralProperty!(TestField, `str`));
    static assert(!hasIntegralProperty!(TestField, `notaproperty`));
    // PropertyType
    static assert(is(PropertyType!(int, `min`) == int));
    static assert(is(PropertyType!(int[], `length`) == size_t));
    static assert(is(PropertyType!(TestField, `x`) == int));
    static assert(is(PropertyType!(TestField, `y`) == const int));
    static assert(is(PropertyType!(TestField, `z`) == int));
    static assert(is(PropertyType!(TestField, `str`) == string));
    static assert(!is(PropertyType!(TestField, `notaproperty`)));
}
