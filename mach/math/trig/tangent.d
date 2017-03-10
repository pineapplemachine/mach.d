module mach.math.trig.tangent;

private:

import mach.math.floats.properties : fisnan, fisinf;
import mach.math.trig.sincos : sin, cos;
import mach.sys.platform : InlineAsm_X86_Any;

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

public:



/// Calculate the tangent of an angle given in radians.
auto tan(in real value){
    static if(InlineAsm_X86_Any){
        if(__ctfe) return tannativeimpl(value);
        return tanx86impl(value);
    }else{
        return tannativeimpl(value);
    }
}



/// Calculate the tangent of an input using the `fptan` x86 instruction.
private auto tanx86impl(in real value){
    static if(InlineAsm_X86_Any){
        // http://x86.renejeschke.de/html/file_module_x86_id_109.html
        // https://courses.engr.illinois.edu/ece390/books/artofasm/CH14/CH14-5.html#HEADING5-1
        asm pure nothrow @nogc{
            // Push value onto FPU register stack
            fld value[EBP];
            // Fiddle with FPU status word and EFLAGS to act on float properties
            fxam;
            fstsw AX;
            sahf;
            // Jump if x is NaN, infinity, or empty, otherwise proceed to fptan
            jc NAN;
            // Calculate tan(ST(0)), store in ST(0), push 1.0 onto FPU stack
            // Value may be out of range (-2^63, +2^63), in which case C2 is set
            fptan;
            // If C2 was not set (value wasn't out of range) then jump to DONE
            fstsw AX;
            sahf;
            jnp DONE;
            // Otherwise, bring it into range by calculating x % pi and try again
            // Push pi onto the FPU register stack
            fldpi;
            // Swap the places of pi and x on the stack for fprem
            fxch;
        REM:
            // Calculate x % pi
            fprem;
            // Evaluate fprem repeatedly until C2 isn't set
            fstsw AX;
            sahf;
            jp REM;
            // Pop pi which was previously pushed onto the stack
            fstp ST(1);
            // x is in range now; calculate the tangent
            fptan;
            jmp DONE;
        NAN:
            fstp ST(0); // Pop input from the FPU stack
        }
        return real.nan;
        DONE: asm pure nothrow @nogc{
            // Pop 1.0 from FPU stack after a successful fptan calculation
            fstp ST(0);
        }
    }else{
        assert(false);
    }
}



/// Calculate the tangent of an input as `sin(x) / cos(x)`.
private auto tannativeimpl(in real value){
    return sin(value) / cos(value);
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats.compare : fidentical, fnearequal;
    import mach.math.floats.properties : fiszero;
    import mach.math.constants : pi, halfpi;
    import mach.math.abs : abs;
    static if(InlineAsm_X86_Any){
        alias TanFns = Aliases!(tan, tannativeimpl, tanx86impl);
    }else{
        alias TanFns = Aliases!(tan, tannativeimpl);
    }
}

unittest{ /// Invalid inputs
    foreach(T; Aliases!(float, double, real)){
        foreach(TanFn; TanFns){
            assert(TanFn(T.nan).fisnan);
            assert(TanFn(-T.nan).fisnan);
            assert(TanFn(T.infinity).fisnan);
            assert(TanFn(-T.infinity).fisnan);
        }
    }
}

unittest{ /// Tangent of zero
    foreach(T; Aliases!(float, double, real)){
        foreach(TanFn; TanFns){
            assert(TanFn(T(0)).fiszero);
            assert(TanFn(-T(0)).fiszero);
        }
    }
}

unittest{ /// Tangent of multiples of pi
    foreach(TanFn; TanFns){
        assert(fnearequal(TanFn(pi), 0));
        assert(fnearequal(TanFn(-pi), 0));
        assert(fnearequal(TanFn(pi + pi), 0));
        assert(fnearequal(TanFn(pi * 8), 0));
    }
}

unittest{ /// Tangent is infinite (or very large in magnitude)
    // Why isn't tan(pi / 2) infinite?
    // See: http://www.website.masmforum.com/tutorials/fptute/fpuchap10.htm
    foreach(TanFn; TanFns){
        import mach.io.stdio;
        assert(abs(TanFn(halfpi)) > 1e18);
        assert(abs(TanFn(-halfpi)) > 1e18);
        assert(abs(TanFn(pi + halfpi)) > 1e18);
        assert(abs(TanFn(-pi - halfpi)) > 1e18);
    }
}

unittest{ /// Verify overflow handling, see https://github.com/dlang/phobos/pull/5114
    assert(!tan(2.0L^^64).fisnan);
    assert(!tan(2.0L^^200).fisnan);
}

unittest{ /// Can be evaluated by CTFE?
    enum x = tan(1);
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
        foreach(TanFn; TanFns){ // Must be correct to at least 12 decimal places
            assert(fnearequal(TanFn(input), expected, 1e-12));
            assert(fnearequal(TanFn(-input), -expected, 1e-12));
            assert(fnearequal(TanFn(input + pi*4), expected, 1e-12));
            assert(fnearequal(TanFn(-input - pi*4), -expected, 1e-12));
        }
    }
}
