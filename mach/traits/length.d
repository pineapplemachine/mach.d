module mach.traits.length;

private:

import std.meta : anySatisfy, allSatisfy;
import std.traits : ReturnType, isSomeFunction;
import std.traits : isArray, isAssociativeArray, isNumeric, isIntegral;

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

template hasNumericLength(T){
    static if(hasLength!T){
        enum bool hasNumericLength = isNumeric!(LengthType!T);
    }else{
        enum bool hasNumericLength = false;
    }
}

template hasIntegralLength(T){
    static if(hasLength!T){
        enum bool hasNumericLength = isIntegral!(LengthType!T);
    }else{
        enum bool hasNumericLength = false;
    }
}

enum hasDollar(T) = isArray!T || is(typeof(T.opDollar));



enum canAccumulateLengths(Iters...) = allSatisfy!(hasNumericLength, Iters);

auto getSummedLength(Iters...)(Iters iters) if(canAccumulateLengths!Iters){
    return getAccumulatedLength!(`+`, Iters)(iters);
}

private auto getAccumulatedLength(string op, Iters...)(Iters iters) if(
    canAccumulateLengths!Iters
){
    size_t length = size_t.init;
    foreach(i, Iter; Iters){
        static if(hasNumericLength!Iter){
            mixin(`
                length = cast(typeof(length))(length ` ~ op ~ ` iters[i].length);
            `);
        }
    }
    return length;
}



enum canCompareLengths(Iters...) = anySatisfy!(hasNumericLength, Iters);

auto getGreatestLength(Iters...)(Iters iters) if(
    canCompareLengths!Iters
){
    return getComparableLength!(`>`, Iters)(iters);
}

auto getSmallestLength(Iters...)(Iters iters) if(
    canCompareLengths!Iters
){
    return getComparableLength!(`<`, Iters)(iters);
}

private auto getComparableLength(string comp, Iters...)(Iters iters) if(
    canCompareLengths!Iters
){
    size_t length = size_t.init;
    bool first = true;
    foreach(i, Iter; Iters){
        static if(hasNumericLength!Iter){
            mixin(`
                auto condition = (
                    first || iters[i].length ` ~ comp ~ ` length
                );
            `);
            if(condition){
                length = cast(typeof(length)) iters[i].length;
                first = false;
            }
        }
    }
    return length;
}



version(unittest){
    import mach.error.unit;
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
unittest{
    tests("Length", {
        testeq(3, getGreatestLength(
            LengthFieldTest(1),
            LengthFieldTest(3),
            LengthFieldTest(2)
        ));
        testeq(1, getSmallestLength(
            LengthFieldTest(1),
            LengthFieldTest(3),
            LengthFieldTest(2)
        ));
        testeq(6, getSummedLength(
            LengthFieldTest(1),
            LengthFieldTest(3),
            LengthFieldTest(2)
        ));
    });
}
