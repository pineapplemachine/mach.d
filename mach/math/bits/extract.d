module mach.math.bits.extract;

private:

//

public:



/// Extract bit from a value at an offset in bits
/// where the offset is known at compile time.
auto extractbit(uint offset, T)(T value) if(
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
/// If length > 32 then the return type is ulong.
auto extractbits(uint offset, uint length, T)(T value) if(
    offset + length <= T.sizeof * 8
){
    static if(length <= 32) alias R = uint;
    else alias R = ulong;
    return extractbits!(R, offset, length)(value);
}

/// Extract bits from a value given an offset and length in bits
/// where the offset and length are known at compile time.
/// The return type is provided explicitly using the `R` template parameter.
auto extractbits(R, uint offset, uint length, T)(T value) if(
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
            enum R mask = (cast(R)(1) << length) - 1;
            return (*(cast(R*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset) & mask;
        }
    }
}



/// Extract bit from a value at an offset in bits.
auto extractbit(T)(T value, in uint offset) in{
    assert(offset < T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable uint byteoffset = offset / 8;
    immutable uint bitoffset = offset % 8;
    immutable uint bitmask = 1 << bitoffset;
    return ((cast(ubyte*) &value)[byteoffset] & bitmask) != 0;
}

/// Extract bits from a value given an offset and length in bits.
auto extractbits(R = ulong, T)(T value, in uint offset, in uint length) in{
    assert(offset + length <= T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable uint byteoffset = offset / 8;
    immutable uint bitoffset = offset % 8;
    if(length == R.sizeof * 8){
        return (*(cast(T*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset);
    }else{
        immutable R mask = (cast(R)(1) << length) - 1;
        return (*(cast(T*)((cast(ubyte*) &value) + byteoffset)) >> bitoffset) & mask;
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
