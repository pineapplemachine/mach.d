module mach.math.bits.inject;

private:

import mach.traits : PointerType, isPointer, isIntegral;
import mach.math.bits.pow2 : pow2d;

public:



// TODO: Test on a big endian platform
// Everything may well break



/// Inject bit into a value where the bit offset is known at compile time.
auto injectbit(uint offset, T)(T value, in bool bit) if(
    offset < T.sizeof * 8
){
    enum byteoffset = offset / 8;
    enum bitoffset = offset % 8;
    T target = value;
    auto ptr = cast(ubyte*) &target + byteoffset;
    *ptr ^= (-(cast(ubyte) bit) ^ *ptr) & (1 << bitoffset);
    return target;
}

/// Injects bit into a value where the bit offset and length are known at
/// compile time.
auto injectbits(uint offset, uint length, T, B)(T value, in B bits) if(
    isIntegral!B && (offset + length) < (T.sizeof * 8)
){
    enum byteoffset = offset / 8;
    enum bitoffset = offset % 8;
    T target = value;
    B* ptr = cast(B*)(cast(ubyte*) &target + byteoffset);
    // TODO: Should be possible to do this in one step instead of two
    ptr[0] &= ~cast(B)(cast(B) pow2d!length << bitoffset); // set target bits to 0
    ptr[0] |= cast(B)(bits << bitoffset); // set to desired value
    static if(length + bitoffset > B.sizeof * 8){
        enum bitslength = B.sizeof * 8;
        enum overflowlength = (length + bitoffset) - bitslength;
        ptr[1] &= ~cast(B)(cast(B) pow2d!overflowlength);
        ptr[1] |= cast(B)(bits >> (bitslength - overflowlength));
    }
    return target;
}



/// Inject bit into a value where the bit offset is not known at compile time.
auto injectbit(T)(T value, in uint offset, in bool bit) in{
    assert(offset < T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable byteoffset = offset / 8;
    immutable bitoffset = offset % 8;
    T target = value;
    auto ptr = cast(ubyte*) &target + byteoffset;
    *ptr ^= (-(cast(ubyte) bit) ^ *ptr) & (1 << bitoffset);
    return target;
}

/// Injects bit into a value where the bit offset and length are not known at
/// compile time.
auto injectbits(T, B)(T value, in uint offset, in uint length, in B bits) if(
    isIntegral!B
) in{
    assert(offset + length <= T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable byteoffset = offset / 8;
    immutable bitoffset = offset % 8;
    T target = value;
    B* ptr = cast(B*)(cast(ubyte*) &target + byteoffset);
    // TODO: Should be possible to do this in one step instead of two
    ptr[0] &= ~cast(B)(pow2d!B(length) << bitoffset); // set target bits to 0
    ptr[0] |= cast(B)(bits << bitoffset); // set to desired value
    if(length + bitoffset > B.sizeof * 8){
        immutable bitslength = B.sizeof * 8;
        immutable overflowlength = (length + bitoffset) - bitslength;
        ptr[1] &= ~cast(B)(pow2d!B(overflowlength));
        ptr[1] |= cast(B)(bits >> (bitslength - overflowlength));
    }
    return target;
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases, NumericSequence;
    import mach.math.bits.extract;
}
unittest{
    tests("Bit injection", {
        tests("Singular", {
            tests("Compile time", {
                testeq(uint(0).injectbit!0(0), 0);
                testeq(uint(0).injectbit!1(0), 0);
                testeq(uint(0).injectbit!0(1), 1);
                testeq(uint(1).injectbit!0(1), 1);
                testeq(uint(0).injectbit!1(1), 2);
                testeq(uint(0).injectbit!2(1), 4);
                testeq(uint(0x7f).injectbit!7(1), 0xff);
                testeq(uint(0xff).injectbit!7(1), 0xff);
                testeq(uint(0xff).injectbit!7(0), 0x7f);
                foreach(T; Aliases!(ubyte, uint, ulong, int, long, float, double, real)){
                    tests(T.stringof, {
                        T value = 0;
                        foreach(i; NumericSequence!(0, T.sizeof * 8)){
                            value = value.injectbit!i(0);
                            testeq(value.extractbit!i, 0);
                            value = value.injectbit!i(1);
                            testeq(value.extractbit!i, 1);
                            value = value.injectbit!i(1);
                            testeq(value.extractbit!i, 1);
                            value = value.injectbit!i(0);
                            testeq(value.extractbit!i, 0);
                        }
                    });
                }
            });
            tests("Runtime", {
                testeq(uint(0).injectbit(0, 0), 0);
                testeq(uint(0).injectbit(1, 0), 0);
                testeq(uint(0).injectbit(0, 1), 1);
                testeq(uint(1).injectbit(0, 1), 1);
                testeq(uint(0).injectbit(1, 1), 2);
                testeq(uint(0).injectbit(2, 1), 4);
                testeq(uint(0x7f).injectbit(7, 1), 0xff);
                testeq(uint(0xff).injectbit(7, 1), 0xff);
                testeq(uint(0xff).injectbit(7, 0), 0x7f);
                foreach(T; Aliases!(ubyte, uint, ulong, int, long, float, double, real)){
                    tests(T.stringof, {
                        T value = 0;
                        foreach(i; 0 .. T.sizeof * 8){
                            value = value.injectbit(i, 0);
                            testeq(value.extractbit(i), 0);
                            value = value.injectbit(i, 1);
                            testeq(value.extractbit(i), 1);
                            value = value.injectbit(i, 1);
                            testeq(value.extractbit(i), 1);
                            value = value.injectbit(i, 0);
                            testeq(value.extractbit(i), 0);
                        }
                    });
                }
            });
        });
        tests("Plural", {
            tests("Compile time", {
                testeq((0x00).injectbits!(0, 4)(0x00), 0x00);
                testeq((0x0f).injectbits!(0, 4)(0x00), 0x00);
                testeq((0x00).injectbits!(0, 4)(0x05), 0x05);
                testeq((0x00).injectbits!(0, 4)(0x0a), 0x0a);
                testeq((0x00).injectbits!(0, 4)(0x0f), 0x0f);
                testeq((0x0f).injectbits!(0, 8)(0xf0), 0xf0);
                testeq((0x0f).injectbits!(4, 4)(0x0f), 0xff);
                testeq(uint(0xffff0000).injectbits!(8, 16)(ushort(0x1234)), 0xff123400);
                testeq(ulong(0xffffffff00000000).injectbits!(16, 32)(uint(0x12345678)), 0xffff123456780000);
            });
            tests("Runtime", {
                testeq((0x00).injectbits(0, 4, 0x00), 0x00);
                testeq((0x0f).injectbits(0, 4, 0x00), 0x00);
                testeq((0x00).injectbits(0, 4, 0x05), 0x05);
                testeq((0x00).injectbits(0, 4, 0x0a), 0x0a);
                testeq((0x00).injectbits(0, 4, 0x0f), 0x0f);
                testeq((0x0f).injectbits(0, 8, 0xf0), 0xf0);
                testeq((0x0f).injectbits(4, 4, 0x0f), 0xff);
                testeq(uint(0xffff0000).injectbits(8, 16, ushort(0x1234)), 0xff123400);
                testeq(ulong(0xffffffff00000000).injectbits(16, 32, uint(0x12345678)), 0xffff123456780000);
            });
        });
    });
}
