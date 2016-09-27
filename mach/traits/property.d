module mach.traits.property;

private:

import std.traits : isNumeric, isIntegral;

public:



/// Determine whether a type possesses some property, by property name.
template hasProperty(alias T, string property){
    enum bool hasProperty = is(typeof({
        mixin(`auto property = T.` ~ property ~ `;`);
    }));
}
/// ditto
template hasProperty(T, string property){
    enum bool hasProperty = is(typeof({
        mixin(`auto property = T.init.` ~ property ~ `;`);
    }));
}

/// Determine whether a type possesses some property matching a predicate
/// template, by property name.
enum hasProperty(alias pred, alias T, string property) = (
    hasProperty!(pred, typeof(T), property)
);
/// ditto
template hasProperty(alias pred, T, string property){
    static if(hasProperty!(T, property)){
        enum bool hasProperty = pred!(PropertyType!(T, property));
    }else{
        enum bool hasProperty = false;
    }
}



// TODO: Just put T at the end of the args list
enum hasNumericProperty(alias T, string property) = (
    hasProperty!(isNumeric, T, property)
);
enum hasNumericProperty(T, string property) = (
    hasProperty!(isNumeric, T, property)
);



template PropertyType(alias T, string property) if(hasProperty!(T, property)){
    mixin(`alias PropertyType = typeof(T.` ~ property ~ `);`);
}
template PropertyType(T, string property) if(hasProperty!(T, property)){
    mixin(`alias PropertyType = typeof(T.init.` ~ property ~ `);`);
}



// TODO: Also move around these args
template hasEnum(T, string name){
    mixin(`
        enum bool hasEnum = __traits(compiles, {enum value = T.` ~ name ~ `;});
    `);
}

template hasEnumType(T, EType, string name){
    mixin(`
        enum bool hasEnumType = __traits(compiles, {enum EType value = T.` ~ name ~ `;});
    `);
}

template hasEnumValue(T, string name, alias value){
    static if(hasEnum!(T, name)){
        mixin(`
            enum bool hasEnumValue = T.` ~ name ~ ` == value;
        `);
    }else{
        enum bool hasEnumValue = false;
    }
}



version(unittest){
    private struct TestField{
        enum bool enumvalue = true;
        int x;
        const int y;
        string str;
        @property int z() const{
            return this.x + this.y;
        }
    }
}
unittest{
    static assert(hasProperty!(TestField, `x`));
    static assert(hasProperty!(TestField, `y`));
    static assert(hasProperty!(TestField, `z`));
    static assert(hasProperty!(TestField, `str`));
    static assert(hasProperty!(TestField(), `x`));
    static assert(hasProperty!(int, `min`));
    static assert(hasProperty!(int, `max`));
    static assert(!hasProperty!(TestField, `notaproperty`));
    static assert(!hasProperty!(int, `hi`));
    static assert(!hasProperty!(void, `hi`));
}
unittest{
    static assert(hasNumericProperty!(TestField, `x`));
    static assert(hasNumericProperty!(TestField(), `x`));
    static assert(!hasNumericProperty!(TestField, `str`));
    static assert(!hasNumericProperty!(TestField, `notaproperty`));
}
unittest{
    static assert(is(PropertyType!(int, `min`) == int));
    static assert(is(PropertyType!(int[], `length`) == size_t));
    static assert(is(PropertyType!(int(0), `min`) == int));
    static assert(is(PropertyType!(TestField, `x`) == int));
    static assert(is(PropertyType!(TestField, `y`) == const int));
    static assert(is(PropertyType!(TestField, `z`) == int));
    static assert(is(PropertyType!(TestField, `str`) == string));
    static assert(is(PropertyType!(TestField(), `x`) == int));
    static assert(is(PropertyType!(const(TestField)(), `x`) == const(int)));
    static assert(!is(PropertyType!(TestField, `notaproperty`)));
}
unittest{
    static assert(hasEnum!(TestField, `enumvalue`));
    static assert(!hasEnum!(TestField, `x`));
    static assert(!hasEnum!(TestField, `notaproperty`));
}
unittest{
    static assert(hasEnumType!(TestField, bool, `enumvalue`));
    static assert(!hasEnumType!(TestField, string, `enumvalue`));
}
unittest{
    static assert(hasEnumValue!(TestField, `enumvalue`, true));
    static assert(!hasEnumValue!(TestField, `enumvalue`, false));
    static assert(!hasEnumValue!(TestField, `x`, true));
    static assert(!hasEnumValue!(TestField, `notaproperty`, true));
}

version(unittest){
    private enum TestEnum{A, B}
}
unittest{
    // hasProperty
    static assert(hasProperty!(TestEnum, `A`));
    static assert(hasProperty!(TestEnum, `B`));
    static assert(!hasProperty!(TestEnum, `X`));
    // PropertyType
    static assert(is(PropertyType!(TestEnum, `A`) == TestEnum));
    static assert(is(PropertyType!(TestEnum, `B`) == TestEnum));
    // hasEnum
    static assert(hasEnum!(TestEnum, `A`));
    static assert(hasEnum!(TestEnum, `B`));
    static assert(!hasEnum!(TestEnum, `X`));
    // hasEnumType
    static assert(hasEnumType!(TestEnum, TestEnum, `A`));
    static assert(hasEnumType!(TestEnum, TestEnum, `B`));
    // hasEnumValue
    static assert(hasEnumValue!(TestEnum, `A`, TestEnum.A));
    static assert(hasEnumValue!(TestEnum, `B`, TestEnum.B));
}
