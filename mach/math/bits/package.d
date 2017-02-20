module mach.math.bits;

private:

/++ Docs

This package provides functionality for bit manipulation.
Perhaps most notably, `extractbit` and `extractbits`, and `injectbit` and
`injectbits`, which can be used to read and write specific bits in a value.

+/

public:

import mach.math.bits.compare;
import mach.math.bits.extract;
import mach.math.bits.hamming;
import mach.math.bits.inject;
import mach.math.bits.pow2;
import mach.math.bits.split;
