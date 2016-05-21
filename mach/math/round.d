module mach.math.round;

private:

import std.traits : isNumeric, isIntegral;
import std.math : abs;

public:

/// Round to the nearest whole number
R round(R = int, N)(in N number) if(isNumeric!N && isNumeric!R){
    static if(isIntegral!N){
        return cast(R) number;
    }else{
        auto remainder = number % 1;
        auto uremainder = abs(remainder);
        auto add = (uremainder >= 0.5) ? (number > 0 ? 1 : -1) : 0;
        static if(isIntegral!R){
            return cast(R) (number + add);
        }else{
            return cast(R) (number + add - remainder);
        }
    }
}

version(unittest) import mach.error.unit;
unittest{
    tests("Rounding", {
        tests("Integers", {
            testeq(round(0), 0);
            testeq(round(1), 1);
            testeq(round(-1), -1);
        });
        tests("Reals", {
            testeq(round(0.0), 0);
            testeq(round(0.25), 0);
            testeq(round(0.5), 1);
            testeq(round(0.75), 1);
            testeq(round(1.0), 1);
            testeq(round(1.25), 1);
            testeq(round(1.5), 2);
            testeq(round(-0.25), 0);
            testeq(round(-0.5), -1);
            testeq(round(-0.75), -1);
        });
        tests("Returning reals", {
            testeq(round!real(0.0), 0.0);
            testeq(round!real(0.5), 1.0);
            testeq(round!real(-0.5), -1.0);
        });
    });
}    
