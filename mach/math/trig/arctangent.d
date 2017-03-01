module mach.math.trig.arctangent;

private:

import mach.math.constants : pi, halfpi, quarterpi, threequarterspi;
import mach.math.polynomial : polynomial;
import mach.math.floats.properties : fisnan, fisinf, fiszero;
import mach.math.floats.extract : fextractsgn;
import mach.math.floats.inject : fcopysgn;
import mach.sys.platform : InlineAsm_X86_Any;

/++ Docs

This module implements the [`atan`](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions)
and [`atan2`](https://en.wikipedia.org/wiki/Atan2) trigonometric functions.

`atan` is the arctangent function for a single floating point input, and it
returns an angle between -π/2 and +π/2 radians.
Its companion, `atan2`, accepts two inputs and finds the arctangent of the
first input divided by the second. This makes it possible to retain quadrant
information, such that `atan2` may return an angle from -π to +π radians.

When any input to either of these functions is NaN, the output is also NaN.

+/

public:



/// Calculate the arctangent of some input.
/// Returns a value that is at least -pi and at most +pi.
real atan(in real value){
    static if(InlineAsm_X86_Any){
        return atanx86impl(value);
    }else{
        return atannativeimpl(value);
    }
}

/// Calculate the arctangent of y / x.
real atan2(in real y, in real x){
    static if(InlineAsm_X86_Any){
        return atan2x86impl(y, x);
    }else{
        return atan2nativeimpl(y, x);
    }
}



/// Calculate the arctangent of y / x.
/// Leverages the `fpatan` x86 instruction.
private real atanx86impl(in real value){
    return atan2x86impl(value, 1.0);
}



/// Native D implementation of arctangent.
/// When working with x86 extended floats, error should reliably be less than 1e-18.
private real atannativeimpl(in real value){
    // Many thanks are due to:
    // http://stackoverflow.com/a/23097989/3478907
    // https://svnweb.freebsd.org/base/head/lib/msun/src/s_atan.c?revision=218509&view=markup
    enum atan1 = pi / 4; // atan(1.0) == pi/4
    enum tanpi8 = 0.414213562373095048801688724209698078569671875376948073176L; // tan(pi/8)
    enum invtanpi8 = 1 / tanpi8;
    
    // MiniMaxApproximation[ArcTan[t], {t, {2^-27,  Tan[Pi / 8]}, 5, 6}]
    enum real[8] P = [
        -1.2413012573967813692492579713841668656360687147411e-27L,
        1.0000000000000000000845328119196165035294658111020L,
        0.29624121585432238342770190161401529036988809666986L,
        1.4458895844978869303089051771857486423499467044458L,
        0.31533130607488799619121749002174880575023284654002L,
        0.54809247071683612835113018471453319940433503182600L,
        0.064616137475684079915165930073434167864960360580068L,
        0.040912686664602122170082679972588677262703985556105L,
    ];
    enum real[9] Q = [
        1.0L,
        0.29624121585432247648767498918464122792729581783192L,
        1.7792229178312030167596639250774433100760972589282L,
        0.41407837802759145369872375343149090574064202798950L,
        0.94116677661220886761241987232830863036326599442816L,
        0.14339402142746016299924377929660256410893354377182L,
        0.14164748814287077229878537470809517505034270802233L,
        0.0073026758571984429459472469840556781844446208738002L,
        0.0020448418327036386394798574466085085964672698877670L,
    ];
    
    if(value.fisnan || value.fiszero){
        return value;
    }else{
        static real poly(in real x){ // 0 <= x <= tan(pi/8)
            return polynomial(x, P) / polynomial(x, Q);
        }
        immutable bool sign = value < 0;
        immutable real absv = sign ? -value : value;
        if(absv >= 0x1p64){ // x is infinite or very large
            return sign ? -halfpi : halfpi;
        }else if(absv <= tanpi8){ // x is in range of the polynomial approximation
            immutable r = poly(absv);
            return sign ? -r : r;
        }else if(absv <= 1){ // atan(x) == atan(1) + atan((x - 1)/(x + 1))
            immutable r = atan1 - poly(-(absv - 1) / (absv + 1));
            return sign ? -r : r;
        }else if(absv < invtanpi8){ // per above, but account for change of sign
            immutable r = atan1 + poly((absv - 1) / (absv + 1));
            return sign ? -r : r;
        }else{ // atan(x) == pi/2 - atan(1/x)
            immutable r = halfpi - poly(1 / absv);
            return sign ? -r : r;
        }
    }
}



/// Calculate the arctangent of y / x.
/// Leverages the `fpatan` x86 instruction.
private real atan2x86impl(in real y, in real x){
    static if(InlineAsm_X86_Any){
        // http://x86.renejeschke.de/html/file_module_x86_id_106.html
        asm pure nothrow @nogc{
            fld y[EBP];
            fld x[EBP];
            fpatan;
        }
    }else{
        assert(false);
    }
}



/// Calculate the arctangent of y / x.
/// Uses a native D implementation.
private real atan2nativeimpl(in real y, in real x){
    // Imitate output of `atan2x86impl`
    if(x.fisnan || y.fisnan){
        return real.nan;
    }else if(y.fiszero){
        return fcopysgn(y, x.fextractsgn ? pi : 0);
    }else if(x.fiszero){
        return fcopysgn(y, halfpi);
    }else if(y.fisinf){
        return fcopysgn(y, x.fisinf ? (x > 0 ? quarterpi : threequarterspi) : halfpi);
    }else if(x.fisinf){
        return fcopysgn(y, x > 0 ? 0 : pi);
    }else if(x > 0){
        return atannativeimpl(y / x);
    }else{
        return atannativeimpl(y / x) + fcopysgn(y, pi);
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats.compare : fidentical, fnearequal;
    alias AtanFns = Aliases!(atan, atanx86impl, atannativeimpl);
    alias Atan2Fns = Aliases!(atan2, atan2x86impl, atan2nativeimpl);
}

unittest{ /// Special cases for atan
    foreach(atanf; AtanFns){
        assert(fiszero(atanf(+0.0)));
        assert(fiszero(atanf(-0.0)));
        assert(fisnan(atanf(real.nan)));
        assert(fidentical(atanf(+real.infinity), +halfpi));
        assert(fidentical(atanf(-real.infinity), -halfpi));
    }
}

unittest{ /// Special cases for atan2
    enum inf = real.infinity;
    foreach(atan2f; Atan2Fns){
        assert(fidentical(atan2f(+0.0, +0.0), +0.0));
        assert(fidentical(atan2f(+0.0, -0.0), +pi));
        assert(fidentical(atan2f(+0.0, +1.0), +0.0));
        assert(fidentical(atan2f(+0.0, -1.0), +pi));
        assert(fidentical(atan2f(+0.0, +inf), +0.0));
        assert(fidentical(atan2f(+0.0, -inf), +pi));
        assert(fidentical(atan2f(-0.0, +0.0), -0.0));
        assert(fidentical(atan2f(-0.0, -0.0), -pi));
        assert(fidentical(atan2f(-0.0, +1.0), -0.0));
        assert(fidentical(atan2f(-0.0, -1.0), -pi));
        assert(fidentical(atan2f(-0.0, +inf), -0.0));
        assert(fidentical(atan2f(-0.0, -inf), -pi));
        assert(fidentical(atan2f(+1, 0), +halfpi));
        assert(fidentical(atan2f(+1, 1), +quarterpi));
        assert(fidentical(atan2f(+1, -1), +threequarterspi));
        assert(fidentical(atan2f(+1, +inf), 0.0));
        assert(fidentical(atan2f(+1, -inf), +pi));
        assert(fidentical(atan2f(-1, 0), -halfpi));
        assert(fidentical(atan2f(-1, 1), -quarterpi));
        assert(fidentical(atan2f(-1, -1), -threequarterspi));
        assert(fidentical(atan2f(-1, +inf), -0.0));
        assert(fidentical(atan2f(-1, -inf), -pi));
        assert(fidentical(atan2f(+inf, +0.0), +halfpi));
        assert(fidentical(atan2f(+inf, -0.0), +halfpi));
        assert(fidentical(atan2f(+inf, +1.0), +halfpi));
        assert(fidentical(atan2f(+inf, -1.0), +halfpi));
        assert(fidentical(atan2f(+inf, +inf), +quarterpi));
        assert(fidentical(atan2f(+inf, -inf), +threequarterspi));
        assert(fidentical(atan2f(-inf, +0.0), -halfpi));
        assert(fidentical(atan2f(-inf, -0.0), -halfpi));
        assert(fidentical(atan2f(-inf, +1.0), -halfpi));
        assert(fidentical(atan2f(-inf, -1.0), -halfpi));
        assert(fidentical(atan2f(-inf, +inf), -quarterpi));
        assert(fidentical(atan2f(-inf, -inf), -threequarterspi));
    }
}
unittest{ // NaN for atan2
    enum nan = real.nan;
    foreach(atan2f; Atan2Fns){
        assert(fisnan(atan2f(0.0, +nan)));
        assert(fisnan(atan2f(0.0, -nan)));
        assert(fisnan(atan2f(+nan, 0.0)));
        assert(fisnan(atan2f(-nan, 0.0)));
        assert(fisnan(atan2f(+nan, +nan)));
        assert(fisnan(atan2f(+nan, -nan)));
        assert(fisnan(atan2f(-nan, +nan)));
        assert(fisnan(atan2f(-nan, -nan)));
    }
}

unittest{ /// Arctangent is correct (or nearly correct) for some set cases
    // Reference values obtained via wolfram alpha.
    enum cases = [ // Array of [input, expected] cases
        [0.125L, 0.124354994546761435031354849163871025573170191769804089915L],
        [0.15L, 0.148889947609497250586530391655867280990525846569136397516L],
        [1.41L, 0.953909302921288376048566263916478645486931094341131554172L],
        [3.0L, 1.249045772398254425829917077281090123077829404129896719054L],
        [20.0L, 1.520837931072953857821315404604906560607307619264045736076L],
        [256.0L, 1.566890096662929647403693026328327054958227209572350054272L],
    ];
    foreach(atancase; cases){
        immutable input = atancase[0];
        immutable expected = atancase[1];
        foreach(atanf; AtanFns){
            assert(fnearequal(atanf(input), expected, 1e-18));
            assert(fnearequal(atanf(-input), -expected, 1e-18));
        }
        foreach(atan2f; Atan2Fns){
            assert(fnearequal(atan2f(+input, +1), +expected, 1e-18));
            assert(fnearequal(atan2f(-input, +1), -expected, 1e-18));
            assert(fnearequal(atan2f(+input, -1), +pi - expected, 1e-18));
            assert(fnearequal(atan2f(-input, -1), -pi + expected, 1e-18));
            immutable qatan = atan(input / 4);
            assert(fnearequal(atan2f(+input, +4), +qatan, 1e-18));
            assert(fnearequal(atan2f(-input, +4), -qatan, 1e-18));
            assert(fnearequal(atan2f(+input, -4), +pi - qatan, 1e-18));
            assert(fnearequal(atan2f(-input, -4), -pi + qatan, 1e-18));
        }
    }
}
