module mach.math.bits.templates;

private:

//

public:



/// Utility function for getting a power of two at compile time.
/// Returns the smallest primitive able to store the given type out of
/// uint, ulong, and ucent.
template pow2(size_t pow){
    static if(pow < 32) enum pow2 = uint(1) << pow;
    else static if(pow < 64) enum pow2 = ulong(1) << pow;
    else static if(pow < 128 && is(ucent)) enum pow2 = ucent(1) << pow;
    else static assert(false, "Value too large to fit in any numeric primitive.");
}

/// Utility function for getting a power of two minus one at compile time.
/// Returns the smallest primitive able to store the given type out of
/// uint, ulong, and ucent.
template pow2d(size_t pow){
    static if(pow < 32) enum pow2d = (uint(1) << pow) - 1;
    else static if(pow == 32) enum pow2d = ~uint(0);
    else static if(pow < 64) enum pow2d = (ulong(1) << pow) - 1;
    else static if(pow == 64) enum pow2d = ~ulong(0);
    else static if(pow < 128 && is(ucent)) enum pow2d = (ucent(1) << pow) - 1;
    else static if(pow == 128 && is(ucent)) enum pow2d = ~ucent(0);
    else static assert(false, "Value too large to fit in any numeric primitive.");
}

/// Get as an alias the smallest primitive unsigned integer type
/// out of uint, ulong, and ucent, which is at least the given
/// number of bits long.
template MinInt(size_t size){
    static if(size <= 32) alias MinInt = uint;
    else static if(size <= 64) alias MinInt = ulong;
    else static if(size <= 128 && is(ucent)) alias MinInt = ucent;
    else static assert(false, "Value too large for any numeric primitive.");
}



unittest{
    static assert(pow2!0 == 1);
    static assert(pow2!1 == 2);
    static assert(pow2!2 == 4);
    static assert(pow2!7 == 128);
    static assert(pow2!8 == 256);
    static assert(pow2!31 == 0x80000000);
    static assert(pow2!63 == 0x8000000000000000);
}

unittest{
    static assert(pow2d!0 == 0);
    static assert(pow2d!1 == 1);
    static assert(pow2d!2 == 3);
    static assert(pow2d!7 == 127);
    static assert(pow2d!8 == 255);
    static assert(pow2d!32 == 0xffffffff);
    static assert(pow2d!64 == 0xffffffffffffffff);
}

unittest{
    static assert(is(MinInt!5 == uint));
    static assert(is(MinInt!8 == uint));
    static assert(is(MinInt!32 == uint));
    static assert(is(MinInt!33 == ulong));
    static assert(is(MinInt!64 == ulong));
    static if(is(ucent)){
        static assert(is(MinInt!65 == ucent));
        static assert(is(MinInt!128 == ucent));
    }
}
