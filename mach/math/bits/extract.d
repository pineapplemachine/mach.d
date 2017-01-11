module mach.math.bits.extract;

private:

import mach.traits : isUnsignedIntegral;

/++ Docs

This module provides functions for determining the value of a specific bit
or bits within a larger value.
The `extractbit` and `extractbits` functions both come in two general varieties:
One implementation for specifying which bits to extract as runtime arguments,
and another, optimized implementation for what that information is known at
compile time.

The `extractbit` function accepts an argument of any type — though using it
to extract bits from anything but primitives is surely foolishness —
and, secondly, as either a runtime or template argument, the offset of the bit
which should be extracted.

+/

unittest{ /// Example
    // Bit offset known at compile time.
    assert(1.extractbit!0 == 1);
    assert(1.extractbit!1 == 0);
    // Bit offset known only at runtime.
    assert(1.extractbit(0) == 1);
    assert(1.extractbit(1) == 0);
}

/++ Docs

The `extractbits` function also accepts an argument of any type and, secondly,
as either a pair of following runtime arguments or as template arguments,
a low bit offset and a length in bits of the portion that should be extracted.

+/

unittest{ /// Example
    // Bit offset known at compile time.
    assert(uint(0xF80).extractbits!(0, 4) == 0x0); // Get 4 bits starting with bit 0.
    assert(uint(0xF80).extractbits!(4, 4) == 0x8); // Get 4 bits starting with bit 4.
    assert(uint(0xF80).extractbits!(8, 4) == 0xF); // Get 4 bits starting with bit 8.
    // Bit offset known only at runtime.
    assert(uint(0xABC).extractbits(0, 4) == 0xC);
    assert(uint(0xABC).extractbits(4, 4) == 0xB);
    assert(uint(0xABC).extractbits(8, 4) == 0xA);
}

/++ Docs

When passing the offset and length as template arguments, the type in which to
store the resulting data is automatically selected from the unsigned integral
primitives.
When passing them as runtime arguments, the default storage type is `ulong`.
This can be changed, however, by providing the desired storage type as a
template argument.

+/

unittest{ /// Example
    assert(uint(0xABCDEF01).extractbits!ubyte(8, 8) == 0xEF);
    assert(uint(0x12345678).extractbits!ushort(16, 16) == 0x1234);
}

public:



// TODO: Test on a big endian platform
// Everything may well break horribly



/// Extract bit from a value at an offset in bits
/// where the offset is known at compile time.
auto extractbit(uint offset, T)(in T value) if(
    offset < T.sizeof * 8
){
    enum byteoffset = offset / 8;
    enum bitoffset = offset % 8;
    enum bitmask = 1 << bitoffset;
    return ((cast(ubyte*) &value)[byteoffset] & bitmask) != 0;
}

/// Extract bits from a value given an offset and length in bits
/// where the offset and length are known at compile time.
/// The return type is inferred from the length argument:
/// If length <= 32 then the return type is uint.
/// If length <= 64 then the return type is ulong.
auto extractbits(uint offset, uint length, T)(in T value) if(
    offset + length <= T.sizeof * 8
){
    static if(length <= 32) alias R = uint;
    else static if(length <= 64) alias R = ulong;
    else static if(length <= 128 && is(ucent)) alias R = ucent;
    else static assert(false, "Too many bits to extract with type inference.");
    return extractbits!(R, offset, length)(value);
}

/// Extract bits from a value given an offset and length in bits
/// where the offset and length are known at compile time.
/// The return type is provided explicitly using the `R` template parameter.
auto extractbits(R, uint offset, uint length, T)(in T value) if(
    isUnsignedIntegral!R &&
    length <= R.sizeof * 8 &&
    offset + length <= T.sizeof * 8
){
    static if(length == 0){
        return cast(R)(0);
    }else{
        enum byteoffset = offset / 8;
        enum bitoffset = offset % 8;
        static if(length == R.sizeof * 8){
            return (*(cast(R*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset);
        }else{
            enum R mask = cast(R)(R(1) << length) - 1;
            return (*(cast(R*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset) & mask;
        }
    }
}



/// Extract bit from a value at an offset in bits.
auto extractbit(T)(in T value, in uint offset) in{
    assert(offset < T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable uint byteoffset = offset / 8;
    immutable uint bitoffset = offset % 8;
    immutable uint bitmask = 1 << bitoffset;
    return ((cast(ubyte*) &value)[byteoffset] & bitmask) != 0;
}

/// Extract bits from a value given an offset and length in bits.
auto extractbits(R = ulong, T)(in T value, in uint offset, in uint length) if(
    isUnsignedIntegral!R
) in{
    assert(offset + length <= T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable uint byteoffset = offset / 8;
    immutable uint bitoffset = offset % 8;
    if(length == R.sizeof * 8){
        return (*(cast(R*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset);
    }else{
        immutable R mask = cast(R)((R(1) << length) - 1);
        return (*(cast(R*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset) & mask;
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Bit extraction", {
        tests("Singular", {
            tests("Compile time", {
                // Extraction from uints
                testeq(uint(0).extractbit!0, 0);
                testeq(uint(1).extractbit!0, 1);
                testeq(uint(1).extractbit!1, 0);
                testeq(uint(7).extractbit!0, 1);
                testeq(uint(7).extractbit!1, 1);
                testeq(uint(7).extractbit!2, 1);
                testeq(uint(7).extractbit!3, 0);
                testeq(uint(7).extractbit!4, 0);
                testeq(uint(7).extractbit!30, 0);
                testeq(uint(7).extractbit!31, 0);
                static assert(!is(typeof({uint(0).extractbit!(-1);})));
                static assert(!is(typeof({uint(0).extractbit!(32);})));
                // From ubyte
                testeq(ubyte(0).extractbit!0, 0);
                testeq(ubyte(1).extractbit!0, 1);
                testeq(ubyte(1).extractbit!1, 0);
                // Extraction of sign bit from floats
                testeq(float(-1).extractbit!31, 1);
                testeq(float(1).extractbit!31, 0);
                testeq(double(-1).extractbit!63, 1);
                testeq(double(1).extractbit!63, 0);
            });
            tests("Runtime", {
                // Extraction from uints
                testeq(uint(0).extractbit(0), 0);
                testeq(uint(1).extractbit(0), 1);
                testeq(uint(1).extractbit(1), 0);
                testeq(uint(7).extractbit(0), 1);
                testeq(uint(7).extractbit(1), 1);
                testeq(uint(7).extractbit(2), 1);
                testeq(uint(7).extractbit(3), 0);
                testeq(uint(7).extractbit(4), 0);
                testeq(uint(7).extractbit(30), 0);
                testeq(uint(7).extractbit(31), 0);
                testfail({uint(0).extractbit(32);});
                // From ubyte
                testeq(ubyte(0).extractbit(0), 0);
                testeq(ubyte(1).extractbit(0), 1);
                testeq(ubyte(1).extractbit(1), 0);
                // Extraction of sign bit from floats
                testeq(float(-1).extractbit(31), 1);
                testeq(float(1).extractbit(31), 0);
                testeq(double(-1).extractbit(63), 1);
                testeq(double(1).extractbit(63), 0);
            });
        });
        tests("Plural", {
            tests("Compile time", {
                // Extraction from uint
                testeq(uint(0x12345678).extractbits!(0, 0), 0x00000000);
                testeq(uint(0x12345678).extractbits!(16, 0), 0x00000000);
                testeq(uint(0x12345678).extractbits!(0, 4), 0x00000008);
                testeq(uint(0x12345678).extractbits!(4, 4), 0x00000007);
                testeq(uint(0x12345678).extractbits!(8, 4), 0x00000006);
                testeq(uint(0x12345678).extractbits!(24, 4), 0x00000002);
                testeq(uint(0x12345678).extractbits!(28, 4), 0x00000001);
                testeq(uint(0x00000000).extractbits!(0, 32), 0x00000000);
                testeq(uint(0x0000000f).extractbits!(0, 32), 0x0000000f);
                testeq(uint(0xffffffff).extractbits!(0, 32), 0xffffffff);
                testeq(uint(0x12345678).extractbits!(0, 32), 0x12345678);
                static assert(is(typeof(uint(0).extractbits!(0, 16)) == uint));
                static assert(is(typeof(uint(0).extractbits!(0, 32)) == uint));
                static assert(is(typeof(ulong(0).extractbits!(0, 16)) == uint));
                static assert(is(typeof(ulong(0).extractbits!(0, 32)) == uint));
                static assert(is(typeof(ulong(0).extractbits!(0, 48)) == ulong));
                static assert(is(typeof(ulong(0).extractbits!(0, 64)) == ulong));
                // From ubyte
                testeq(uint(0x12).extractbits!(0, 4), 0x02);
                testeq(uint(0x12).extractbits!(4, 4), 0x01);
                testeq(uint(0x12).extractbits!(0, 8), 0x12);
            });
            tests("Runtime", {
                // Extraction from uint
                testeq(uint(0x12345678).extractbits(0, 0), 0x00000000);
                testeq(uint(0x12345678).extractbits(16, 0), 0x00000000);
                testeq(uint(0x12345678).extractbits(0, 4), 0x00000008);
                testeq(uint(0x12345678).extractbits(4, 4), 0x00000007);
                testeq(uint(0x12345678).extractbits(8, 4), 0x00000006);
                testeq(uint(0x12345678).extractbits(24, 4), 0x00000002);
                testeq(uint(0x12345678).extractbits(28, 4), 0x00000001);
                testeq(uint(0x00000000).extractbits(0, 32), 0x00000000);
                testeq(uint(0x0000000f).extractbits(0, 32), 0x0000000f);
                testeq(uint(0xffffffff).extractbits(0, 32), 0xffffffff);
                testeq(uint(0x12345678).extractbits(0, 32), 0x12345678);
                // From ubyte
                testeq(uint(0x12).extractbits(0, 4), 0x02);
                testeq(uint(0x12).extractbits(4, 4), 0x01);
                testeq(uint(0x12).extractbits(0, 8), 0x12);
            });
        });
    });
}
