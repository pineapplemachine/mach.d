module mach.math.floats.neighbors;

private:

import mach.traits : isFloatingPoint, IEEEFormat, IEEEFormatOf;
import mach.math.bits.pow2 : pow2d;
import mach.math.floats.extract : fextractsgn, fextractexp, fextractsig;
import mach.math.floats.inject : finjectsig, finjectsgn, fcompose, fcopysgn;
import mach.math.floats.properties : fisinf, fisnan;

public:



/// Get the successor of a floating point number.
/// That is, the smallest representable value which is greater than the input.
/// Returns +inf if the input is +inf or the largest representable value.
/// Returns the smallest representable finite value if the input is -inf.
/// Returns NaN if the input is NaN.
auto fsuccessor(T)(in T value) if(isFloatingPoint!T){
    if(value < 0) return value.fmagpredecessor;
    else return value.fmagsuccessor.finjectsgn(0);
}

/// Get the successor of a floating point number,
/// regarding magnitude but not respecting sign.
auto fmagsuccessor(T)(in T value) if(isFloatingPoint!T){
    if(value.fisinf){
        return fcopysgn(value, T.infinity);
    }else if(value.fisnan){
        return value;
    }else{
        enum Format = IEEEFormatOf!T;
        enum sigsize = Format.sigsize;
        auto sgn = value.fextractsgn;
        auto exp = value.fextractexp;
        auto sig = value.fextractsig;
        if(sig < pow2d!sigsize){
            return value.finjectsig(sig + 1);
        }else if(exp < Format.expmax - 1){
            return fcompose!T(sgn, exp + 1, 0);
        }else{
            return fcopysgn(value, T.infinity);
        }
    }
}



/// Get the predecessor of a floating point number.
/// That is, the greatest representable value which is smaller than the input.
/// Returns -inf if the input is -inf or the smallest representable value.
/// Returns the greatest representable finite value if the input is +inf.
/// Returns NaN if the input is NaN.
auto fpredecessor(T)(in T value) if(isFloatingPoint!T){
    if(value > 0) return value.fmagpredecessor;
    else return value.fmagsuccessor.finjectsgn(1);
}

/// Get the predecessor of a floating point number,
/// regarding magnitude but not respecting sign.
auto fmagpredecessor(T)(in T value) if(isFloatingPoint!T){
    if(value.fisinf){
        return fcopysgn(value, T.max);
    }else if(value.fisnan){
        return value;
    }else{
        enum Format = IEEEFormatOf!T;
        enum sigsize = Format.sigsize;
        auto sgn = value.fextractsgn;
        auto exp = value.fextractexp;
        auto sig = value.fextractsig;
        if(sig > 0){
            return value.finjectsig(sig - 1);
        }else{
            return fcompose!T(sgn, exp - 1, pow2d!sigsize);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
}
unittest{
    tests("Float neighbors", {
        foreach(T; Aliases!(float, double, real)){
            tests(T.stringof, {
                testeq(T.infinity.fsuccessor, T.infinity);
                testeq((-T.infinity).fsuccessor, -T.max);
                testeq(T.max.fsuccessor, T.infinity);
                testeq(T(0).fsuccessor.fextractsig, 1);
                testeq(T.infinity.fpredecessor, T.max);
                testeq((-T.infinity).fpredecessor, -T.infinity);
                testeq((-T.max).fpredecessor, -T.infinity);
                T[] narray = [
                    0.0, -0.0, 1, -1, 10, -10, 10.55, -10.55,
                    40.125, -40.125, 256, -256, 12345.6, -12345.6,
                    T.max, -T.max, T.min_normal, -T.min_normal
                ];
                foreach(n; narray){
                    testeq(n.fsuccessor.fpredecessor, n);
                    testeq(n.fpredecessor.fsuccessor, n);
                }
            });
        }
    });
}
