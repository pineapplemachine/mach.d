module mach.math.trig.tangent;

private:

import mach.traits : isFloatingPoint;
import mach.math.constants : pi;
import mach.math.polynomial : polynomial;
import mach.math.floats.properties : fisnan, fisinf;
import core.math : sin, cos;

/// Constants used by native implementation
enum halfpi = pi / 2;
enum quarterpi = pi / 4;
enum threequarterspi = halfpi + quarterpi;
enum eigthpi = pi / 8;

version(D_InlineAsm_X86){
    enum X86Asm = true;
}else version(D_InlineAsm_X86_64){
    enum X86Asm = true;
}else{
    enum X86Asm = false;
}

/++ Docs

This module implements the `tan`
[trigonometric function](https://en.wikipedia.org/wiki/Trigonometric_functions#Sine.2C_cosine_and_tangent).
The input angle must be measured in radians.
Returned values are always of type `real`.

Depending on the platform, `tan(pi / 2)` may or may not produce infinity.
Strictly speaking, a return value of infinity indicates that a rounding error
has occurred, since `real(pi / 2)` is not exactly equal to `pi / 2`.
`tan(float.infinity)` and `tan(float.nan)` produce NaN.
Very large positive or negative values will potentially produce inaccurate
results due to rounding errors.

+/

unittest{ /// Example
    import mach.math.floats : fnearequal;
    import mach.math.constants : pi;
    assert(fnearequal(tan(pi), 0));
    assert(fnearequal(tan(1.0), 1.5574077246549022, 1e-12));
}

/++ Docs

This module also defines a `fasttan` function, which may use a faster algorithm
at the expense of accuracy.

+/

unittest{ /// Example
    import mach.math.floats : fnearequal;
    assert(fnearequal(fasttan(1.0), 1.5574077246549022, 1e-6));
}

public:



/// Calculate the tangent of an angle given in radians.
auto tan(in real value){
    static if(X86Asm){
        return tanx86impl(value);
    }else{
        return tannativeimpl(value);
    }
}

/// Calculate the tangent of an angle given in radians.
/// Depending on platform or other factors, may choose a faster implementation
/// over a more accurate one.
auto fasttan(in real value){
    static if(X86Asm){
        return tanx86impl(value);
    }else{
        return fasttannativeimpl(value);
    }
}



/// Calculate the tangent of an input using the `fptan` x86 instruction.
auto tanx86impl(T)(in T value) if(isFloatingPoint!T){
    static if(X86Asm){
        immutable x = cast(real) value;
        // http://x86.renejeschke.de/html/file_module_x86_id_109.html
        // https://courses.engr.illinois.edu/ece390/books/artofasm/CH14/CH14-5.html#HEADING5-1
        asm pure nothrow @nogc{
            // Load value, push to FPU register stack
            fld x[EBP];
            // Set C3, C2, C0 to represent type of FP value, and C1 to its sign
            fxam;
            // Store FPU status word into register AX; load AH (upper 8 bits of AX) into EFLAGS
            fstsw AX;
            sahf;
            // Jump if x is NaN, infinity, or empty, otherwise proceed to fptan
            jc NAN;
        TAN:
            // Calculate tan(ST(0)), store in ST(0), push 1.0 onto FPU stack
            // Value may be out of range (-2^63, +2^63), in which case C2 is set
            fptan;
            // If C2 was not set (value wasn't out of range) then exit
            fstsw AX;
            sahf;
            jnp DONE;
            // Otherwise, bring it into range by calculating remainder(x / pi) and try again
            // Push pi onto the FPU register stack
            fldpi;
            // Swap the places of pi (ST(0)) and x (ST(1)) on the stack
            fxch;
        REM:
            // Calculate remainder(x / pi)
            // This instruction should be evaluated repeatedly until C2 is not set
            fprem;
            // If C2 was set, do it again
            fstsw AX;
            sahf;
            jp REM;
            // Otherwise, proceed to calculate tangent
            // Pop pi which was previously pushed onto the stack
            fstp ST(1);
            // Calculate tangent
            fptan;
            jmp DONE;
        NAN:
            fstp ST(0); // Pop value from the FPU stack
        }
        return real.nan;
        TEST: {}
        DONE: asm pure nothrow @nogc{
            // Pop 1.0 from FPU stack after a successful fptan calculation
            fstp ST(0);
        }
    }else{
        assert(false);
    }
}



/// Calculate the tangent of an input as `cos(x) / sin(x)`.
auto tannativeimpl(T)(in T value) if(isFloatingPoint!T){
    return sin(value) / cos(value);
}



/// Calculate the approximate tangent of an input with a native D algorithm.
/// Faster than `tannativeimpl`, but less accurate. Slower than `tanx86impl`.
/// https://svnweb.freebsd.org/base/head/lib/msun/src/k_tanf.c?revision=239192&view=markup
/// http://mathonweb.com/help_ebook/html/algorithms.htm#tan
auto fasttannativeimpl(T)(in T value) if(isFloatingPoint!T){
    enum real[] Coeff = [
        0x15554d3418c99f.0p-54, // 0.333331395030791399758
        0x1112fd38999f72.0p-55, // 0.133392002712976742718
        0x1b54c91d865afe.0p-57, // 0.0533812378445670393523
        0x191df3908c33ce.0p-58, // 0.0245283181166547278873
        0x185dadfcecf44e.0p-61, // 0.00297435743359967304927
        0x1362b9bf971bcd.0p-59, // 0.00946564784943673166728
    ];
    if(value.fisinf || value.fisnan){
        return real.nan;
    }else{
        auto impl(in real x){ // 0 <= x <= pi/4
            immutable z = x * x;
            immutable r = Coeff[4] + z * Coeff[5];
            immutable t = Coeff[2] + z * Coeff[3];
            immutable w = z * z;
            immutable s = z * x;
            immutable u = Coeff[0] + z * Coeff[1];
            return (x + s * u) + (s * w) * (t + w * r);
        }
        immutable bool sign = value < 0;
        immutable realval = cast(real)(sign ? -value : value) % pi;
        immutable bool invert = realval > halfpi;
        immutable x = invert ? pi - realval : realval;
        immutable reciprocal = x > quarterpi;
        immutable y = reciprocal ? halfpi - x : x;
        immutable result = impl(y);
        immutable sresult = (sign ^ invert) ? -result : result;
        return reciprocal ? 1 / sresult : sresult;
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats.compare : fidentical, fnearequal;
    import mach.math.floats.properties : fiszero;
    static if(X86Asm){
        alias TanFns = Aliases!(tan, tannativeimpl, tanx86impl);
    }else{
        alias TanFns = Aliases!(tan, tannativeimpl);
    }
    alias FastTanFns = Aliases!(fasttan, fasttannativeimpl);
    alias AllTanFns = Aliases!(TanFns, FastTanFns);
}

unittest{ /// Invalid inputs
    foreach(T; Aliases!(float, double, real)){
        foreach(TanFn; AllTanFns){
            assert(TanFn(T.nan).fisnan);
            assert(TanFn(-T.nan).fisnan);
            assert(TanFn(T.infinity).fisnan);
            assert(TanFn(-T.infinity).fisnan);
        }
    }
}

unittest{ /// Tangent of zero
    foreach(T; Aliases!(float, double, real)){
        foreach(TanFn; AllTanFns){
            assert(TanFn(T(0)).fiszero);
            assert(TanFn(-T(0)).fiszero);
        }
    }
}

unittest{ /// Tangent of multiples of pi
    foreach(TanFn; AllTanFns){
        assert(fnearequal(TanFn(pi), 0));
        assert(fnearequal(TanFn(-pi), 0));
        assert(fnearequal(TanFn(pi + pi), 0));
        assert(fnearequal(TanFn(pi * 8), 0));
    }
}

unittest{ /// Tangent is infinite/very large
    // Why isn't tan(pi/2) infinite? See: http://www.website.masmforum.com/tutorials/fptute/fpuchap10.htm
    foreach(TanFn; AllTanFns){
        assert(TanFn(pi * 0.5) > 1e18);
        assert(TanFn(pi * -0.5) < -1e18);
        assert(TanFn(pi * 1.5) > 1e18);
        assert(TanFn(pi * -1.5) < -1e18);
    }
}

unittest{ /// Verify overflow handling, see https://github.com/dlang/phobos/pull/5114
    assert(!tan(2.0L^^64).fisnan);
    assert(!tan(2.0L^^200).fisnan);
}

unittest{ /// Tangent is correct (or nearly correct) for some set cases
    // Reference values obtained via wolfram alpha. Thanks, wolfram alpha
    enum cases = [ // Array of [input, expected] cases
        [0.1L, 0.100334672085450545058080045781111536819004804576442040022L],
        [0.5L, 0.546302489843790513255179465780285383297551720179791246164L],
        [1.0L, 1.557407724654902230506974807458360173087250772381520038383L],
        [1.25L, 3.009569673862831288157563894386243931391637699606062181047L],
        [1.41L, 6.165356144552025547675946974931103727726891659852815539310L],
        [2.0L, -2.18503986326151899164330610231368254343201774622766316456L],
        [2.5L, -0.74702229723866027935535268782527455790411695688301127906L],
        [2.75L, -0.41291789448493248776396687326112912373625582036206288993L],
        [3.0L, -0.14254654307427780529563541053391349322609228490180464763L],
        [3.1L, -0.04161665458563598940100494124940586984325789605529963474L],
        [3.25L, 0.108834025513329719513960397400008301510964634807683842406L],
    ];
    foreach(tancase; cases){
        immutable input = tancase[0];
        immutable expected = tancase[1];
        foreach(TanFn; TanFns){ // Regular `tan` must be correct to at least 12 decimal places
            assert(fnearequal(TanFn(input), expected, 1e-12));
            assert(fnearequal(TanFn(-input), -expected, 1e-12));
            assert(fnearequal(TanFn(input + pi*4), expected, 1e-12));
            assert(fnearequal(TanFn(-input - pi*4), -expected, 1e-12));
        }
        foreach(TanFn; FastTanFns){ // Fast `tan` must be correct to at least 6 decimal places
            assert(fnearequal(TanFn(input), expected, 1e-6));
            assert(fnearequal(TanFn(-input), -expected, 1e-6));
            assert(fnearequal(TanFn(input + pi*4), expected, 1e-6));
            assert(fnearequal(TanFn(-input - pi*4), -expected, 1e-6));
        }
    }
}
