module mach.math.trig.sincos;

private:

import mach.sys.platform : InlineAsm_X86_Any;

/++ Docs

This module provides the [`sin`, `cos`, and `sincos` trigonometric functions]
(https://en.wikipedia.org/wiki/Trigonometric_functions#Sine.2C_cosine_and_tangent).

`sin` can be used to compute the sine of an angle given in radians, and `cos`
the cosine.
`sincos` computes both at once, which will often be more performant than making
separate calls to `sin` and `cos` when both values are required.

When the input to `sin` or `cos` is infinite or NaN, the output will be NaN.
When the input to `sincos` is infinite or NaN, the output will have NaN
representing both its sine and cosine results.

+/

unittest{ /// Example
    import mach.math.floats.compare : fnearequal;
    assert(fnearequal(sin(1), 0.84147098480789650665L, 1e-18));
    assert(fnearequal(cos(1), 0.54030230586813971740L, 1e-18));
}

unittest{ /// Example
    import mach.math.floats.compare : fnearequal;
    immutable both = sincos(1); // May be faster than separate calls
    assert(fnearequal(both.sin, 0.84147098480789650665L, 1e-18));
    assert(fnearequal(both.cos, 0.54030230586813971740L, 1e-18));
}

public:



public import core.math : sin, cos;



/// Type returned by `sincos` function.
struct SinCosResult{
    real sin;
    real cos;
}



/// Calculate the sine and cosine of an angle given in radians.
/// On some platforms, this will be more performant than making separate calls
/// to `sin` and `cos`.
SinCosResult sincos(in real value){
    static if(InlineAsm_X86_Any){
        return sincosx86impl(value);
    }else{
        return sincossepimpl(value);
    }
}



/// Calculate sine and cosine using seperate calls to `sin` and `cos`.
private SinCosResult sincossepimpl(in real value){
    return SinCosResult(sin(value), cos(value));
}


import mach.io.stdio;
/// Calculate sine and cosine simultaneously using the `fsincos` x86 instruction.
/// More efficient than calculating the values separately.
private SinCosResult sincosx86impl(in real value){
    static if(InlineAsm_X86_Any){
        // TODO: How to not wrap in a function returning creal?
        static creal impl(in real value){
            // http://x86.renejeschke.de/html/file_module_x86_id_115.html
            asm pure nothrow @nogc{
                // Push value onto FPU register stack
                fld value[EBP];
                // Fiddle with FPU status word and EFLAGS to act on float properties
                fxam;
                fstsw AX;
                sahf;
                // Jump if x is NaN, infinity, or empty, otherwise proceed to fsincos
                jc NAN;
                // Replace ST(0) with sine and push cosine onto the stack
                // Value may be out of range (-2^63, +2^63), in which case C2 is set
                fsincos;
                // If C2 was not set (value wasn't out of range) then jump to DONE
                fstsw AX;
                sahf;
                jnp DONE;
                // Otherwise, bring it into range by calculating x % 2pi and try again
                // Push 2pi onto the stack
                fldpi;
                fldpi;
                faddp;
                // Swap places of 2pi and x on the stack for fprem
                fxch;
            REM:
                // Calculate x % 2pi
                fprem;
                // Evaluate fprem repeatedly until C2 isn't set
                fstsw AX;
                sahf;
                jp REM;
                // Pop 2*pi which was previously pushed onto the stack
                fstp ST(1);
                // x is in range now; calculate sin and cos
                fsincos;
                jmp DONE;
            NAN:
                fstp ST(0); // Pop input from the FPU stack
            }
            return creal.init;
            DONE: {}
        }
        immutable c = impl(value);
        return SinCosResult(c.re, c.im);
    }else{
        assert(false);
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats.compare : fnearequal;
    import mach.math.floats.properties : fisnan;
    import mach.math.constants : pi;
    enum halfpi = pi / 2;
}

unittest{ // Sine of multiples of pi/2
    assert(fnearequal(sin(pi * -2.0), +0, 1e-18));
    assert(fnearequal(sin(pi * -1.5), +1, 1e-18));
    assert(fnearequal(sin(pi * -1.0), +0, 1e-18));
    assert(fnearequal(sin(pi * -0.5), -1, 1e-18));
    assert(fnearequal(sin(pi * +0.0), +0, 1e-18));
    assert(fnearequal(sin(pi * +0.5), +1, 1e-18));
    assert(fnearequal(sin(pi * +1.0), +0, 1e-18));
    assert(fnearequal(sin(pi * +1.5), -1, 1e-18));
    assert(fnearequal(sin(pi * +2.0), +0, 1e-18));
}
unittest{ // Cosine of multiples of pi/2
    assert(fnearequal(cos(pi * -2.0), +1, 1e-18));
    assert(fnearequal(cos(pi * -1.5), +0, 1e-18));
    assert(fnearequal(cos(pi * -1.0), -1, 1e-18));
    assert(fnearequal(cos(pi * -0.5), +0, 1e-18));
    assert(fnearequal(cos(pi * +0.0), +1, 1e-18));
    assert(fnearequal(cos(pi * +0.5), +0, 1e-18));
    assert(fnearequal(cos(pi * +1.0), -1, 1e-18));
    assert(fnearequal(cos(pi * +1.5), +0, 1e-18));
    assert(fnearequal(cos(pi * +2.0), +1, 1e-18));
}

unittest{ /// NaN and infinite inputs
    foreach(T; Aliases!(float, double, real)){
        foreach(input; [T.nan, -T.nan, T.infinity, -T.infinity]){
            assert(sin(input).fisnan);
            assert(cos(input).fisnan);
            immutable x = sincos(input);
            assert(x.sin.fisnan);
            assert(x.cos.fisnan);
        }
    }
}

unittest{ /// Verify overflow handling, see https://github.com/dlang/phobos/pull/5114
    assert(!sin(2.0L^^64).fisnan);
    assert(!sin(2.0L^^200).fisnan);
    assert(!cos(2.0L^^64).fisnan);
    assert(!cos(2.0L^^200).fisnan);
    immutable x = sincos(2.0L^^64);
    assert(!x.sin.fisnan && !x.cos.fisnan);
    immutable y = sincos(2.0L^^200);
    assert(!y.sin.fisnan && !y.cos.fisnan);
}

unittest{ /// Check sin and cosine for some set cases
    // Reference values obtained via wolfram alpha.
    enum cases = [ // Array of [input, expected sine] cases
        [-20.0L, -0.91294525072762765437609998384568230129793258370818995630L, 0.408082061813391986062267860927644957099299510316252822755L],
        [-2.0L, -0.90929742682568169539601986591174484270225497144789026837L, -0.41614683654714238699756822950076218976600077107554489075L],
        [-1.5L, -0.99749498660405443094172337114148732270665142592211582194L, 0.070737201667702910088189851434268709085091027563346869422L],
        [1.41L, 0.987100101013850341429088861942238185563198355770948052922L, 0.160104311554831190163562549360915143006505128901299723911L],
        [3.0L, 0.141120008059867222100744802808110279846933264252265584151L, -0.98999249660044545727157279473126130239367909661558832881L],
        [8.5L, 0.798487112623490286666913160339112585889626327738868917541L, -0.60201190268482361534842652295699870029606776360435523539L],
        [12.0L, -0.53657291800043497166537422824240179231573852827804064839L, 0.843853958732492104653955293173621783168087152604565012588L],
        [22.0L, -0.00885130929040387592169025681577233246328920395133256644L, -0.99996082639463712645417473921269377413598846747941929305L],
    ];
    foreach(sccase; cases){
        immutable input = sccase[0];
        immutable expectedsin = sccase[1];
        immutable expectedcos = sccase[2];
        assert(fnearequal(sin(input), expectedsin, 1e-18));
        assert(fnearequal(cos(input), expectedcos, 1e-18));
        assert(fnearequal(cos(input - halfpi), expectedsin, 1e-18));
        assert(fnearequal(sin(input + halfpi), expectedcos, 1e-18));
        immutable sim = sincos(input);
        assert(fnearequal(sim.sin, expectedsin, 1e-18));
        assert(fnearequal(sim.cos, expectedcos, 1e-18));
    }
}
