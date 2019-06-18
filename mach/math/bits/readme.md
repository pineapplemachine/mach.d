# mach.math.bits


This package provides functionality for bit manipulation.
Perhaps most notably, `extractbit` and `extractbits`, and `injectbit` and
`injectbits`, which can be used to read and write specific bits in a value.


## mach.math.bits.clz


The `clz` function returns the number of leading zeros for an integer value.
It returns the number of bits in the value when there were no set bits.

``` D
assert(clz!int(-1) == 0);
assert(clz!int(0) == 32);
assert(clz!int(0x00F00000) == 8);
```


## mach.math.bits.compare


The `bitsidentical` function can be used to compare the low bits of two
arbtirary values to determine whether their contents are identical.
The number of low bits to compare must be passed as a template argument.
When two inputs of the same type are passed, the number of bits is optional
and defaults to the total number of bits in that type.

``` D
// Compare all the bits
assert(bitsidentical(0xabcdef, 0xabcdef));
// Compare low bits
assert(bitsidentical!16(ushort(0x1234), uint(0xffff1234)));
```


## mach.math.bits.ctz


The `ctz` function returns the number of trailing zeros for an integer value.
It returns the number of bits in the value when there were no set bits.

``` D
assert(ctz!int(1) == 0);
assert(ctz!int(0) == 32);
assert(ctz!int(0x00F00000) == 20);
```


## mach.math.bits.extract


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

``` D
// Bit offset known at compile time.
assert(1.extractbit!0 == 1);
assert(1.extractbit!1 == 0);
// Bit offset known only at runtime.
assert(1.extractbit(0) == 1);
assert(1.extractbit(1) == 0);
```


The `extractbits` function also accepts an argument of any type and, secondly,
as either a pair of following runtime arguments or as template arguments,
a low bit offset and a length in bits of the portion that should be extracted.

``` D
// Bit offset known at compile time.
assert(uint(0xF80).extractbits!(0, 4) == 0x0); // Get 4 bits starting with bit 0.
assert(uint(0xF80).extractbits!(4, 4) == 0x8); // Get 4 bits starting with bit 4.
assert(uint(0xF80).extractbits!(8, 4) == 0xF); // Get 4 bits starting with bit 8.
// Bit offset known only at runtime.
assert(uint(0xABC).extractbits(0, 4) == 0xC);
assert(uint(0xABC).extractbits(4, 4) == 0xB);
assert(uint(0xABC).extractbits(8, 4) == 0xA);
```


When passing the offset and length as template arguments, the type in which to
store the resulting data is automatically selected from the unsigned integral
primitives.
When passing them as runtime arguments, the default storage type is `ulong`.
This can be changed, however, by providing the desired storage type as a
template argument.

``` D
assert(uint(0xABCDEF01).extractbits!ubyte(8, 8) == 0xEF);
assert(uint(0x12345678).extractbits!ushort(16, 16) == 0x1234);
```


## mach.math.bits.hamming


The `hamming` function can be used to get the hamming weight of a primitive
integral type, which is a count of the number of 1 bits representing its
binary value.

``` D
assert(uint(0x101010).hamming == 3); // 3 bits
assert(uint(0x111111).hamming == 6); // 6 bits
assert(uint(0x000000).hamming == 0); // No bits
```


## mach.math.bits.inject


This module implements the `injectbit` and `injectbits` functions, which can be
used to get the result of setting a bit or bits within a value.
Note that neither function actually modifies its input, but returns a copy
with the pertinent bits changed.

The `injectbit` function accepts a value to inject the bit into, the value
of the bit and, as either a runtime or template argument, the value to set
the bit to.

``` D
// Bit offset known at compile time.
assert(0.injectbit!0(1) == 1);
assert(0.injectbit!1(1) == 2);
assert(0.injectbit!8(1) == 256);
// Bit offset known only at runtime.
assert(0.injectbit(0, 1) == 1);
assert(0.injectbit(1, 1) == 2);
assert(0.injectbit(8, 1) == 256);
```


The `injectbits` function performs similarly, but instead of specifying a single
offset, an offset and length in bits is specified. And instead of specifying a
boolean to set the single bit to, an unsigned integral value is given which
contains the desired pattern of bits.

``` D
// Bit offset known at compile time.
assert(0.injectbits!(0, 4)(0xF) == 0xF);
assert(0.injectbits!(4, 4)(0xF) == 0xF0);
assert(0.injectbits!(16, 8)(0xFF) == 0xFF0000);
// Bit offset known only at runtime.
assert(0.injectbits(0, 4, 0xF) == 0xF);
assert(0.injectbits(4, 4, 0xF) == 0xF0);
assert(0.injectbits(16, 8, 0xFF) == 0xFF0000);
```


For both `injectbit` and `injectbits`,
when it is known at compile time that the value being injected into is in a
state where all the bits being set are currently initialized to 0, the
`assumezero` flag may be set in order to perform the operation more efficiently.

``` D
// Assume the bits being set are currently 0.
assert(0.injectbit!(0, true)(1) == 1);
assert(0.injectbits!(0, 4, true)(0x7) == 0x7);
// Now don't assume it.
assert(1.injectbit!(0, false)(1) == 1);
assert(uint(0xF).injectbits!(0, 4, false)(0x7) == 0x7);
```


Note that behavior of `injectbits` is undefined when the input has bits set
outside of the length of bits that is being injected.
When compiling in debug mode asserts will fail when junk bits are present,
but outside debug mode the function will simply behave incorrectly.

``` D
import mach.test.assertthrows : assertthrows;
import core.exception : AssertError;
// Because the value 0xFF has bits set outside its four low bits,
// which are the ones being injected, this is an illegal operation.
debug assertthrows!AssertError({
    auto nope = 0.injectbits!(0, 4)(0xFF);
});
```


## mach.math.bits.split


The `lowbits` and `highbits` functions can be use to acquire the low or high
half of the bits comprising an input integer value, respectively.
The output is always the same type as the input.

``` D
assert(uint(0x12345678).highbits == 0x1234);
assert(uint(0x12345678).lowbits == 0x5678);
```


The `splitbits` function may be used to get both at once.
It returns a type with `low` and `high` attributes, and can also be indexed
as though it was a tuple.

``` D
auto split = ushort(0xabcd).splitbits;
// Access via the `high` and `low` attributes:
assert(split.high == 0xab);
assert(split.low == 0xcd);
// Access via indexing:
assert(split[1] == 0xab);
assert(split[0] == 0xcd);
```


Additionally, the `mergebits` function may be used to perform the complementary
operation where an integer is built from its separately-known high and low bits.

``` D
assert(mergebits(uint(0x1234), uint(0x5678)) == uint(0x12345678));
```


