module mach.math.trig.inverse;

private:

import mach.math.sqrt : sqrt;
import mach.math.trig.arctangent : atan2;

/++ Docs

This module defines the `asin` and `acos` [trigonometric functions]
(https://en.wikipedia.org/wiki/Inverse_trigonometric_functions).
Their inputs are expected to be at least -1 and at most +1, otherwise they
return NaN.

+/

unittest{ /// Example
    import mach.math.floats.compare : fnearequal;
    import mach.math.trig.sincos : sin, cos;
    assert(fnearequal(sin(asin(0.5)), 0.5, 1e-18));
    assert(fnearequal(cos(acos(0.5)), 0.5, 1e-18));
}

public:



/// Returns the arcsine of the input, which must be an angle given in radians.
real asin(in real value){
    return atan2(value, sqrt(1 - value * value));
}

/// Returns the arccosine of the input, which must be an angle given in radians.
real acos(in real value){
    return atan2(sqrt(1 - value * value), value);
}



private version(unittest){
    import mach.math.constants : pi, halfpi;
    import mach.math.floats.compare : fidentical, fnearequal;
    import mach.math.floats.properties : fisnan;
}

unittest{ /// Inputs 0, 1, and -1
    assert(fidentical(asin(+0), +0));
    assert(fidentical(asin(-1), -halfpi));
    assert(fidentical(asin(+1), +halfpi));
    assert(fidentical(acos(-1), +pi));
    assert(fidentical(acos(+0), +halfpi));
    assert(fidentical(acos(+1), +0));
}

unittest{ /// Illegal inputs
    assert(fisnan(asin(+2)));
    assert(fisnan(asin(-2)));
    assert(fisnan(acos(+2)));
    assert(fisnan(acos(-2)));
    assert(fisnan(asin(real.nan)));
    assert(fisnan(asin(-real.nan)));
    assert(fisnan(acos(real.nan)));
    assert(fisnan(acos(-real.nan)));
    assert(fisnan(asin(real.infinity)));
    assert(fisnan(asin(-real.infinity)));
    assert(fisnan(acos(real.infinity)));
    assert(fisnan(acos(-real.infinity)));
}

unittest{ /// Arcsine and arccosine are correct (or nearly correct) for some set cases
    // Reference values obtained via wolfram alpha.
    enum sincases = [ // Array of [input, expected] cases
        [0.125L, 0.125327831168065396874566986357084718048147726838672375233L],
        [0.25L, 0.252680255142078653485657436993710972252193733096838193633L],
        [0.35L, 0.357571103645510286714838492320642567846741324989487763251L],
        [0.5L, 0.523598775598298873077107230546583814032861566562517636829L],
        [0.75L, 0.848062078981481008052944338998418080073366213263112642860L],
        [0.9L, 1.119769514998634186686677055845399615895162186403302882375L],
    ];
    foreach(sincase; sincases){
        immutable input = sincase[0];
        immutable expected = sincase[1];
        assert(fnearequal(asin(+input), +expected, 1e-18));
        assert(fnearequal(asin(-input), -expected, 1e-18));
        assert(fnearequal(acos(+sqrt(1 - input * input)), +expected, 1e-18));
    }
}
