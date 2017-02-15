module mach.math.bits.compare;

private:

import mach.math.bits.pow2 : pow2d;

/++ Docs

The `bitsidentical` function can be used to compare the low bits of two
arbtirary values to determine whether their contents are identical.
The number of low bits to compare must be passed as a template argument.
When two inputs of the same type are passed, the number of bits is optional
and defaults to the total number of bits in that type.

+/

unittest{ /// Example
    // Compare all the bits
    assert(bitsidentical(0xabcdef, 0xabcdef));
    // Compare low bits
    assert(bitsidentical!16(ushort(0x1234), uint(0xffff1234)));
}

public:



/// Get whether the bits constituting two inputs are exactly identical.
@safe bool bitsidentical(T)(in T a, in T b){
    return bitsidentical!(T.sizeof * 8)(a, b);
}

/// Get whether the lowest n bits of two inputs are exactly identical.
/// The given number of bits must be less than or equal to the number of bits
/// in each input.
/// When the inputted number of bits is 0, this function always returns true.
@trusted bool bitsidentical(uint bits, A, B)(in A a, in B b){
    static assert(bits <= A.sizeof * 8 && bits <= B.sizeof * 8,
        "Input types too small to compare the given number of bits."
    );
    static if(bits == 0){
        return true;
    }else static if(bits == 8){
        const aint = cast(ubyte*) &a;
        const bint = cast(ubyte*) &b;
        return *aint == *bint;
    }else static if(bits == 16){
        const aint = cast(ushort*) &a;
        const bint = cast(ushort*) &b;
        return *aint == *bint;
    }else static if(bits == 32){
        const aint = cast(uint*) &a;
        const bint = cast(uint*) &b;
        return *aint == *bint;
    }else static if(bits == 64){
        const aint = cast(ulong*) &a;
        const bint = cast(ulong*) &b;
        return *aint == *bint;
    }else static if(bits == 128 && is(ucent)){
        const aint = cast(ucent*) &a;
        const bint = cast(ucent*) &b;
        return *aint == *bint;
    }else static if(bits == 80){
        // Optimized implementation for x86 extended floats
        const alow = cast(ulong*) &a;
        const blow = cast(ulong*) &b;
        const ahigh = cast(ushort*) &a;
        const bhigh = cast(ushort*) &b;
        return *alow == *blow && ahigh[4] == bhigh[4];
    }else{
        enum words = bits / 64;
        enum remainder = bits % 64;
        const awords = cast(ulong*) &a;
        const bwords = cast(ulong*) &b;
        static if(words > 0){
            for(uint i = 0; i < words; i++){
                if(awords[i] != bwords[i]) return false;
            }
        }
        static if(remainder > 0){
            enum mask = pow2d!(remainder + 1);
            return (awords[words] & mask) == (bwords[words] & mask);
        }else{
            return true;
        }
    }
}



unittest{ /// Implicit bit count
    struct Test80{short a; long b;}
    struct Test96{int a; long b;}
    struct TestBig{uint[100] a;}
    // Identical
    assert(bitsidentical(int(0), int(0)));
    assert(bitsidentical(int(-256), int(-256)));
    assert(bitsidentical(double(2.0), double(2.0)));
    assert(bitsidentical(double.nan, double.nan));
    assert(bitsidentical(Test80(12, 34), Test80(12, 34)));
    assert(bitsidentical(Test96(12, 34), Test96(12, 34)));
    // Not identical
    assert(!bitsidentical(int(0), int(1)));
    assert(!bitsidentical(int(1), int(0)));
    assert(!bitsidentical(double.nan, -double.nan));
    assert(!bitsidentical(Test80(12, 34), Test80(12, 99)));
    assert(!bitsidentical(Test80(12, 34), Test80(99, 34)));
    assert(!bitsidentical(Test96(12, 34), Test96(12, 99)));
    assert(!bitsidentical(Test96(12, 34), Test96(99, 34)));
    // Lots of bits
    TestBig biga; biga.a[10] = 125;
    TestBig bigb; bigb.a[10] = 125;
    TestBig bigc; bigc.a[10] = 126;
    assert(bitsidentical(biga, bigb));
    assert(bitsidentical(bigb, biga));
    assert(!bitsidentical(biga, bigc));
    assert(!bitsidentical(bigb, bigc));
}

unittest{ /// Explicit bit count
    assert(bitsidentical!16(uint(0x1234), uint(0xff1234)));
    assert(!bitsidentical!16(uint(0x1234), uint(0xff1235)));
    assert(bitsidentical!16(ushort(0x1234), uint(0xff1234)));
    assert(!bitsidentical!16(ushort(0x1234), uint(0xff1235)));
}
