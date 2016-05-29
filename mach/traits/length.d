module mach.traits.length;

private:

import std.traits : ReturnType, isSomeFunction;
import std.traits : isArray, isAssociativeArray;

public:



/// Distinct from standard library template in that length is not required to
/// be implicitly convertible to ulong.
template hasLength(T){
    enum bool hasLength = is(typeof((inout int = 0){
        auto len = T.init.length;
    }));
}

template LengthType(T) if(hasLength!T){
    static if(isArray!T || isAssociativeArray!T){
        alias LengthType = size_t;
    }else static if(isSomeFunction!(T.length)){
        alias LengthType = ReturnType!(T.length);
    }else{
        alias LengthType = typeof(T.length);
    }
}

enum hasDollar(T) = isArray!T || is(typeof(T.opDollar));



version(unittest){
    private struct LengthFieldTest{
        double length;
    }
    private struct LengthPropertyTest{
        double len;
        @property auto length(){
            return this.len;
        }
    }
    private struct NoLengthTest{
        double len;
    }
    private struct DollarAliasTest{
        int len;
        alias opDollar = len;
    }
    private struct DollarPropertyTest{
        int len;
        @property auto opDollar(){
            return this.len;
        }
    }
    private struct NoDollarTest{
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
