# mach.math.bits


This package provides functionality for bit manipulation.
Perhaps most notably, `extractbit` and `extractbits`, and `injectbit` and
`injectbits`, which can be used to read and write specific bits in a value.


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
import mach.error.mustthrow : mustthrow;
debug mustthrow({
    // Because the value 0xFF has bits set outside its four low bits,
    // which are the ones being injected, this is an illegal operation.
    0.injectbits!(0, 4)(0xFF);
});
```


