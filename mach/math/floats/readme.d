module mach.math.floats.readme;

private:

import mach.math.floats;

/++ md

# mach.math.floats

This package contains functions for reading and manipulating floating point
values efficiently and in a format-agnostic way.

## mach.math.floats.extract

This module provides functionality for extracting the individual components of
floating point values.

+/

unittest{
    float zero = 0;
    assert(zero.fextractsgn == 0); // Sign
    assert(zero.fextractexp == 0); // Unbiased exponent
    assert(zero.fextractsexp == -126); // Biased exponent
    assert(zero.fextractsig == 0); // Raw significand
    assert(zero.fextractnsig == 0); // Normalized significand
}

/++ md

## mach.math.floats.inject

Complement to the `extract` module, this one provides implementations for
setting the components of floating point values.

+/

unittest{
    auto x = float(0).finjectsgn(1); // Sign
    assert(x.fextractsgn == 1);
    auto y = float(0).finjectexp(100); // Exponent
    assert(y.fextractexp == 100);
    auto z = float(0).finjectsig(1000); // Significand
    assert(z.fextractsig == 1000);
}

/++ md

## mach.math.floats.neighbors

Each float has a successor and a predecessor - defined as the least greater and
greatest lesser values, respectively. This module provides functions for
retrieving those neighbors given a floating point value.

+/

unittest{
    assert(float.max.fsuccessor == float.infinity);
    assert(float.infinity.fpredecessor == float.max);
    assert(float(0).fsuccessor.fpredecessor == 0);
}

/++ md

## mach.math.floats.properties

Defines properties for checking various states a floating point value can occupy,
including being NaN, infinity, normal, subnormal (or denormal), and unnormal.

+/

unittest{
    assert(float.nan.fisnan);
    assert(float.infinity.fisinf);
    assert(float(0).fiszero);
    assert(float(0).fisnormal);
}
