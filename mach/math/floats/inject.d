module mach.math.floats.inject;

private:

import mach.traits : isFloatingPoint, isIntegral, IEEEFormat, IEEEFormatOf;
import mach.math.bits.inject : injectbit, injectbits;
import mach.math.floats.extract : fextractsgn;

public:



/// Compose a floating point number given a sign, exponent, and significand.
auto fcompose(T, Sig)(in bool sgn, in uint exp, in Sig sig) if(
    isFloatingPoint!T && isIntegral!Sig
){
    enum Format = IEEEFormatOf!T;
    enum sgnoffset = Format.sgnoffset;
    enum expoffset = Format.expoffset;
    enum expsize = Format.expsize;
    enum sigoffset = Format.sigoffset;
    enum sigsize = Format.sigsize;
    immutable T a = T(0).injectbit!(sgnoffset, true)(sgn);
    immutable T b = a.injectbits!(expoffset, expsize, true)(exp);
    immutable T c = b.injectbits!(sigoffset, sigsize, true)(sig);
    return c;
}



/// Get a float the same as the input, but with the given sign.
auto finjectsgn(T)(in T value, in bool sgn) if(
    isFloatingPoint!T
){
    enum offset = IEEEFormatOf!T.sgnoffset;
    return value.injectbit!(offset)(sgn);
}

/// Get a float the same as the input, but with the given exponent bits.
auto finjectexp(T)(in T value, in uint exp) if(
    isFloatingPoint!T
){
    enum Format = IEEEFormatOf!T;
    enum offset = Format.expoffset;
    enum size = Format.expsize;
    return value.injectbits!(offset, size)(exp);
}

/// Get a float the same as the input, but with the given significand bits.
auto finjectsig(T, Sig)(in T value, in Sig sig) if(
    isFloatingPoint!T && isIntegral!Sig
){
    enum Format = IEEEFormatOf!T;
    enum offset = Format.sigoffset;
    enum size = Format.sigsize;
    return value.injectbits!(offset, size)(sig);
}



/// Get a float the same as `dst`, but with the same sign as `src`.
auto fcopysgn(Src, Dst)(in Src src, in Dst dst) if(
    isFloatingPoint!Src && isFloatingPoint!Dst
){
    return dst.finjectsgn(src.fextractsgn);
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
    import mach.math.floats.extract : fextractexp, fextractsig;
}
unittest{
    tests("Float inject", {
        struct Float{bool sgn; uint exp; ulong sig;}
        foreach(T; Aliases!(float, double, real)){
            tests(T.stringof, {
                foreach(f; [
                    Float(0, 0, 0),
                    Float(1, 0, 0),
                    Float(0, 1, 0),
                    Float(1, 1, 0),
                    Float(0, 0, 1),
                    Float(1, 0, 1),
                    Float(0, 120, 32000),
                    Float(1, 120, 32000),
                    Float(0, 127, 0),
                    Float(1, 127, 0),
                    Float(0, 127, 8388607),
                    Float(1, 127, 8388607),
                ]){
                    auto composed = fcompose!T(f.sgn, f.exp, f.sig);
                    testeq(composed.fextractsgn, f.sgn);
                    testeq(composed.fextractexp, f.exp);
                    testeq(composed.fextractsig, f.sig);
                }
            });
        }
    });
}
