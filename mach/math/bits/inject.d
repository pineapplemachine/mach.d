module mach.math.bits.inject;

private:

import mach.traits : PointerType, isPointer, isIntegral;
import mach.math.bits.pow2 : pow2d;

/++ Docs

This module implements the `injectbit` and `injectbits` functions, which can be
used to get the result of setting a bit or bits within a value.
Note that neither function actually modifies its input, but returns a copy
with the pertinent bits changed.

The `injectbit` function accepts a value to inject the bit into, the value
of the bit and, as either a runtime or template argument, the value to set
the bit to.

+/

unittest{ /// Example
    // Bit offset known at compile time.
    assert(0.injectbit!0(1) == 1);
    assert(0.injectbit!1(1) == 2);
    assert(0.injectbit!8(1) == 256);
    // Bit offset known only at runtime.
    assert(0.injectbit(0, 1) == 1);
    assert(0.injectbit(1, 1) == 2);
    assert(0.injectbit(8, 1) == 256);
}

/++ Docs

The `injectbits` function performs similarly, but instead of specifying a single
offset, an offset and length in bits is specified. And instead of specifying a
boolean to set the single bit to, an unsigned integral value is given which
contains the desired pattern of bits.

+/

unittest{ /// Example
    // Bit offset known at compile time.
    assert(0.injectbits!(0, 4)(0xF) == 0xF);
    assert(0.injectbits!(4, 4)(0xF) == 0xF0);
    assert(0.injectbits!(16, 8)(0xFF) == 0xFF0000);
    // Bit offset known only at runtime.
    assert(0.injectbits(0, 4, 0xF) == 0xF);
    assert(0.injectbits(4, 4, 0xF) == 0xF0);
    assert(0.injectbits(16, 8, 0xFF) == 0xFF0000);
}

/++ Docs

For both `injectbit` and `injectbits`,
when it is known at compile time that the value being injected into is in a
state where all the bits being set are currently initialized to 0, the
`assumezero` flag may be set in order to perform the operation more efficiently.

+/

unittest{ /// Example
    // Assume the bits being set are currently 0.
    assert(0.injectbit!(0, true)(1) == 1);
    assert(0.injectbits!(0, 4, true)(0x7) == 0x7);
    // Now don't assume it.
    assert(1.injectbit!(0, false)(1) == 1);
    assert(uint(0xF).injectbits!(0, 4, false)(0x7) == 0x7);
}

/++ Docs

Note that behavior of `injectbits` is undefined when the input has bits set
outside of the length of bits that is being injected.
When compiling in debug mode asserts will fail when junk bits are present,
but outside debug mode the function will simply behave incorrectly.

+/

unittest{ /// Example
    import mach.error.mustthrow : mustthrow;
    debug mustthrow({
        // Because the value 0xFF has bits set outside its four low bits,
        // which are the ones being injected, this is an illegal operation.
        0.injectbits!(0, 4)(0xFF);
    });
}

public:



// TODO: Test on a big endian platform
// Everything may well break horribly



/// Inject bit into a value where the bit offset is known at compile time.
/// When the `assumezero` template argument is true, the operation is able
/// to be optimized by assuming the targeted bits are all initialized to 0.
auto injectbit(uint offset, bool assumezero = false, T)(
    T value, in bool bit
) if(
    offset < T.sizeof * 8
){
    enum byteoffset = offset / 8;
    enum bitoffset = offset % 8;
    T target = value;
    auto ptr = cast(ubyte*) &target + byteoffset;
    static if(assumezero){
        *ptr |= cast(ubyte) bit << bitoffset;
    }else{
        *ptr ^= (-(cast(int) bit) ^ *ptr) & (1 << bitoffset);
    }
    return target;
}

/// Injects bit into a value where the bit offset and length are known at
/// compile time.
/// When the `assumezero` template argument is true, the operation is able
/// to be optimized by assuming the targeted bits are all initialized to 0.
auto injectbits(uint offset, uint length, bool assumezero = false, T, B)(
    T value, in B bits
) if(
    isIntegral!B && (offset + length) < (T.sizeof * 8)
){
    debug{
        // Check for junk bits, which will break the implementation.
        assert((bits & ~pow2d!length) == 0);
    }
    enum byteoffset = offset / 8;
    enum bitoffset = offset % 8;
    T target = value;
    B* ptr = cast(B*)(cast(ubyte*) &target + byteoffset);
    static if(assumezero){
        ptr[0] |= cast(B)(bits << bitoffset);
    }else{
        // TODO: Should be possible to do this in one step instead of two
        ptr[0] &= ~cast(B)(cast(B) pow2d!length << bitoffset); // set target bits to 0
        ptr[0] |= cast(B)(bits << bitoffset); // set to desired value
    }
    static if(length + bitoffset > B.sizeof * 8){
        enum bitslength = B.sizeof * 8;
        enum overflowlength = (length + bitoffset) - bitslength;
        static if(assumezero){
            ptr[1] |= cast(B)(bits >> (bitslength - overflowlength));
        }else{
            ptr[1] &= ~cast(B)(cast(B) pow2d!overflowlength);
            ptr[1] |= cast(B)(bits >> (bitslength - overflowlength));
        }
    }
    return target;
}



/// Inject bit into a value where the bit offset is not known at compile time.
/// When the `assumezero` template argument is true, the operation is able
/// to be optimized by assuming the targeted bits are all initialized to 0.
auto injectbit(bool assumezero = false, T)(
    T value, in uint offset, in bool bit
) in{
    assert(offset < T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    immutable byteoffset = offset / 8;
    immutable bitoffset = offset % 8;
    T target = value;
    auto ptr = cast(ubyte*) &target + byteoffset;
    static if(assumezero){
        *ptr |= cast(ubyte) bit << bitoffset;
    }else{
        *ptr ^= (-(cast(int) bit) ^ *ptr) & (1 << bitoffset);
    }
    return target;
}

/// Injects bit into a value where the bit offset and length are not known at
/// compile time.
/// When the `assumezero` template argument is true, the operation is able
/// to be optimized by assuming the targeted bits are all initialized to 0.
auto injectbits(bool assumezero = false, T, B)(
    T value, in uint offset, in uint length, in B bits
) if(
    isIntegral!B
) in{
    assert(offset + length <= T.sizeof * 8, "Bit offset exceeds size of parameter.");
}body{
    debug{
        // Check for junk bits, which will break the implementation.
        assert((bits & ~pow2d!B(length)) == 0);
    }
    immutable byteoffset = offset / 8;
    immutable bitoffset = offset % 8;
    T target = value;
    B* ptr = cast(B*)(cast(ubyte*) &target + byteoffset);
    static if(assumezero){
        ptr[0] |= cast(B)(bits << bitoffset); // set to desired value
    }else{
        // TODO: Should be possible to do this in one step instead of two
        ptr[0] &= ~cast(B)(pow2d!B(length) << bitoffset); // set target bits to 0
        ptr[0] |= cast(B)(bits << bitoffset); // set to desired value
    }
    if(length + bitoffset > B.sizeof * 8){
        immutable bitslength = B.sizeof * 8;
        immutable overflowlength = (length + bitoffset) - bitslength;
        static if(assumezero){
            ptr[1] |= cast(B)(bits >> (bitslength - overflowlength));
        }else{
            ptr[1] &= ~cast(B)(pow2d!B(overflowlength));
            ptr[1] |= cast(B)(bits >> (bitslength - overflowlength));
        }
    }
    return target;
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases, NumericSequence;
    import mach.math.bits.extract;
    
    void SingularTests(alias func)(){
        func!(0)(uint(0), 0, 0);
        func!(1)(uint(0), 0, 0);
        func!(0)(uint(0), 1, 1);
        func!(0)(uint(1), 1, 1);
        func!(0)(uint(1), 0, 0);
        func!(1)(uint(0), 1, 2);
        func!(2)(uint(0), 1, 4);
        func!(7)(uint(0x7f), 1, 0xff);
        func!(7)(uint(0xff), 1, 0xff);
        func!(7)(uint(0xff), 0, 0x7f);
        foreach(T; Aliases!(ubyte, uint, ulong, int, long, float, double)){
            tests(T.stringof, {
                T value = 0;
                foreach(i; NumericSequence!(0, T.sizeof * 8)){
                    value = func!(i)(value, 0);
                    testeq(value.extractbit!i, 0);
                    value = func!(i)(value, 1);
                    testeq(value.extractbit!i, 1);
                    value = func!(i)(value, 1);
                    testeq(value.extractbit!i, 1);
                    value = func!(i)(value, 0);
                    testeq(value.extractbit!i, 0);
                }
            });
        }
    }
    auto singularcttest(uint offset, T, E = typeof(null))(
        T input, bool bit, E expected = E.init
    ){
        immutable value = injectbit!(offset, false)(input, bit);
        static if(!is(E == typeof(null))){
            testeq(value, expected);
            if(input.extractbit!offset == 0){
                testeq(injectbit!(offset, true)(input, bit), expected);
            }
        }
        return value;
    }
    auto singularrttest(uint offset, T, E = typeof(null))(
        T input, bool bit, E expected = E.init
    ){
        immutable value = injectbit!false(input, offset, bit);
        static if(!is(E == typeof(null))){
            testeq(value, expected);
            if(input.extractbit!offset == 0){
                testeq(injectbit!true(input, offset, bit), expected);
            }
        }
        return value;
    }
    
    void PluralTests(alias func)(){
        func!(0, 4)(0x00, 0x00, 0x00);
        func!(0, 4)(0x0f, 0x00, 0x00);
        func!(0, 4)(0x00, 0x05, 0x05);
        func!(0, 4)(0x00, 0x0a, 0x0a);
        func!(0, 4)(0x00, 0x0f, 0x0f);
        func!(0, 8)(0x0f, 0xf0, 0xf0);
        func!(4, 4)(0x0f, 0x0f, 0xff);
        func!(8, 16)(uint(0xffff0000), ushort(0x1234), 0xff123400);
        func!(16, 32)(ulong(0xffffffff00000000), uint(0x12345678), 0xffff123456780000);
    }
    auto pluralcttest(uint offset, uint length, T, B, E = typeof(null))(
        T input, B bits, E expected = E.init
    ){
        immutable value = injectbits!(offset, length, false)(input, bits);
        static if(!is(E == typeof(null))){
            testeq(value, expected);
            if(input.extractbits!(offset, length) == 0){
                testeq(injectbits!(offset, length, true)(input, bits), expected);
            }
        }
        return value;
    }
    auto pluralrttest(uint offset, uint length, T, B, E = typeof(null))(
        T input, B bits, E expected = E.init
    ){
        immutable value = injectbits!false(input, offset, length, bits);
        static if(!is(E == typeof(null))){
            testeq(value, expected);
            if(input.extractbits!(offset, length) == 0){
                testeq(injectbits!true(input, offset, length, bits), expected);
            }
        }
        return value;
    }
}

unittest{
    tests("Bit injection", {
        tests("Singular", {
            tests("Compile time", {
                SingularTests!singularcttest();
            });
            tests("Runtime", {
                SingularTests!singularrttest();
            });
        });
        tests("Plural", {
            tests("Compile time", {
                PluralTests!pluralcttest();
                debug tests("Junk bits", {
                    testfail({
                        0.injectbits!(0, 1)(2);
                    });
                });
            });
            tests("Runtime", {
                PluralTests!pluralrttest();
                debug tests("Junk bits", {
                    testfail({
                        0.injectbits(0, 1, 2);
                    });
                });
            });
        });
    });
}
