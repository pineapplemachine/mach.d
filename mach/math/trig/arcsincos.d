module mach.math.trig.arcsincos;

private:

import core.math : sqrt;
import mach.math.floats.properties : fisinf;
import mach.math.trig.arctangent : atan2;

/++ Docs

This module implements the [`asin` and `acos` trigonometric functions]
(https://en.wikipedia.org/wiki/Inverse_trigonometric_functions).

`asin` accepts a sine value and outputs the corresponding angle,
a value between -π/2 and +π/2 radians.

`acos` accepts a cosine value and outputs the corresponding angle,
a value between 0 and π radians.

When the input to `asin` or `acos` is outside the range -1 to +1
inclusive, the functions will output NaN.

+/

unittest{ /// Example
    import mach.math.floats.compare : fnearequal;
    assert(fnearequal(asin(0.5), 0.52359877559829887307L, 1e-18));
    assert(fnearequal(acos(0.5), 1.04719755119659774615L, 1e-18));
}

public:



/// Compute the arcsine of an input value.
real asin(in real sine) {
    if(fisinf(sine)) {
        return real.nan;
    }else {
        return atan2(sine, sqrt(1 - sine * sine));
    }
}

/// Compute the arccosine of an input value.
real acos(in real cosine) {
    if(fisinf(cosine)) {
        return real.nan;
    }else {
        return atan2(sqrt(1 - cosine * cosine), cosine);
    }
}



private version(unittest){
    import mach.math.floats.compare : fnearequal;
    import mach.math.floats.properties : fisnan;
    import mach.math.constants : pi;
}

unittest{ // Arcsine and arccosine of +1, 0, and -1
    assert(fnearequal(asin(-1), -pi / 2, 1e-18));
    assert(fnearequal(asin(+0), 0, 1e-18));
    assert(fnearequal(asin(+1), +pi / 2, 1e-18));
    assert(fnearequal(acos(-1), +pi, 1e-18));
    assert(fnearequal(acos(+0), +pi / 2, 1e-18));
    assert(fnearequal(acos(+1), 0, 1e-18));
}

unittest{ /// NaN and infinite inputs produce NaN
    assert(asin(+double.nan).fisnan);
    assert(asin(-double.nan).fisnan);
    assert(asin(+double.infinity).fisnan);
    assert(asin(-double.infinity).fisnan);
    assert(acos(+double.nan).fisnan);
    assert(acos(-double.nan).fisnan);
    assert(acos(+double.infinity).fisnan);
    assert(acos(-double.infinity).fisnan);
}

unittest{ /// Outputs outside the range [-1, +1] produce NaN
    assert(asin(+1.5).fisnan);
    assert(asin(-1.5).fisnan);
    assert(acos(+1.5).fisnan);
    assert(acos(-1.5).fisnan);
}

unittest{ /// Can be evaluated by CTFE?
    enum x = asin(1);
    enum y = acos(1);
}

unittest{ /// Check asin and acos for some set cases
    // Reference values obtained via wolfram alpha.
    enum cases = [ // Array of [value, arcsine, arccosine] cases
        [-0.7L, -0.77539749661075306374035335271498711355578873864116199L, 2.346193823405649682971675044354738555654373438328714904L],
        [-0.25L, -0.25268025514207865348565743699371097225219373309683819L, 1.823476581936975272716979128633462414350778432784391104L],
        [0.5L, 0.523598775598298873077107230546583814032861566562517636L, 1.047197551196597746154214461093167628065723133125035273L],
        [0.8L, 0.927295218001612232428512462922428804057074108572240527L, 0.643501108793284386802809228717322638041510591115312382L],
    ];
    foreach(sccase; cases){
        immutable value = sccase[0];
        immutable expectedasin = sccase[1];
        immutable expectedacos = sccase[2];
        assert(fnearequal(asin(value), expectedasin, 1e-18));
        assert(fnearequal(acos(value), expectedacos, 1e-18));
        assert(fnearequal(asin(-value), -expectedasin, 1e-18));
        assert(fnearequal(acos(-value), pi - expectedacos, 1e-18));
    }
}
