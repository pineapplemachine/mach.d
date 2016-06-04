module mach.math.round;

private:

import std.traits : isNumeric, isIntegral;
import std.math : abs;

public:



/// Round to the nearest whole number.
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

/// Get the ceiling of one number divided by another.
R ceil(R = int, N)(in N x, in N y) if(isNumeric!N && isNumeric!R){
    static if(isIntegral!N){
        auto floor = x / y;
        return cast(R) (floor + (floor * y < x));
    }else{
        auto result = x / y;
        if(result % 1 == 0){
            return cast(R) result;
        }else if(result >= 0){
            return cast(R) (result + (1 - (result % 1)));
        }else{
            return cast(R) (result - result % 1);
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
    tests("Ceil", {
        tests("Integers", {
            testeq(ceil(10, 2), 5);
            testeq(ceil(10, 3), 4);
            testeq(ceil(-10, 3), -3);
            testeq(ceil!real(10, 2), 5.0);
            testeq(ceil!real(10, 3), 4.0);
            testeq(ceil!real(-10, 3), -3.0);
        });
        tests("Reals", {
            testeq(ceil(10.0, 2.0), 5);
            testeq(ceil(10.0, 3.0), 4);
            testeq(ceil(-10.0, 3.0), -3);
            testeq(ceil!real(10.0, 2.0), 5.0);
            testeq(ceil!real(10.0, 3.0), 4.0);
            testeq(ceil!real(-10.0, 3.0), -3.0);
        });
    });
}    
