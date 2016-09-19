module mach.math.ispow2;

private:

import std.traits : isIntegral, isSigned;
import mach.math.bits : hamming;

public:



/// Get whether a number is a power of two.
/// TODO: Overrides for signed and float types
bool ispow2(T)(T n) if(isIntegral!T && !isSigned!T){
    return n == 0 || n.hamming == 1;
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Is power of 2", {
        test(0u.ispow2);
        test(1u.ispow2);
        test(2u.ispow2);
        test(4u.ispow2);
        test(8u.ispow2);
        test(16u.ispow2);
        test(256u.ispow2);
        test(65536u.ispow2);
        test(uint(1 << 30).ispow2);
        testf(3u.ispow2);
        testf(5u.ispow2);
        testf(11u.ispow2);
        testf(100000u.ispow2);
    });
}
