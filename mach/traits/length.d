module mach.traits.length;

private:

import mach.traits.array : isArray;
import mach.traits.primitives : isNumeric;
import mach.traits.property : hasProperty, PropertyType;

public:



template hasLength(T...) if(T.length == 1){
    enum bool hasLength = hasProperty!(T, `length`);
}

template LengthType(T...) if(T.length == 1 && hasLength!T){
    alias LengthType = PropertyType!(T, `length`);
}

template hasNumericLength(T...) if(T.length == 1){
    static if(hasLength!T){
        enum bool hasNumericLength = isNumeric!(LengthType!T);
    }else{
        enum bool hasNumericLength = false;
    }
}

enum hasDollar(T) = isArray!T || is(typeof(T.opDollar));



version(unittest){
    private:
    struct LengthFieldTest{
        double length;
    }
    struct LengthPropertyTest{
        double len;
        @property auto length(){
            return this.len;
        }
    }
    struct NoLengthTest{
        double len;
    }
    struct DollarAliasTest{
        int len;
        alias opDollar = len;
    }
    struct DollarPropertyTest{
        int len;
        @property auto opDollar(){
            return this.len;
        }
    }
    struct NoDollarTest{
        double notadollar;
    }
}

unittest{
    // hasLength
    static assert(hasLength!(int[]));
    static assert(hasLength!LengthFieldTest);
    static assert(hasLength!LengthPropertyTest);
    static assert(!hasLength!NoLengthTest);
    // LengthType
    static assert(is(LengthType!(int[]) == size_t));
    static assert(is(LengthType!LengthFieldTest == double));
    static assert(is(LengthType!LengthPropertyTest == double));
    // hasDollar
    static assert(hasDollar!(int[]));
    static assert(hasDollar!DollarAliasTest);
    static assert(hasDollar!DollarPropertyTest);
    static assert(!hasDollar!NoDollarTest);
}
