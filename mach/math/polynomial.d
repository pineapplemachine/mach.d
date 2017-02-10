module mach.math.polynomial;

private:

import mach.traits : isNumeric, CommonType, isArray, ArrayElementType;

/++ Docs

The `polynomial` function accepts a value and an array of coefficients as
input, and calculates `c[0] * x^0 + c[1] * x^1 + c[2] * x^2 + ...` where
coefficients following the last element of the passed coefficients array
are zero.

In this computation `x` must be passed as a runtime argument, but the array
of coefficients may be passed as either a runtime or a template argument.

+/

unittest{ /// Example
    // Coefficients passed as a runtime argument
    assert(polynomial(2, [1, 2, 3]) == 17); // (1 * 2^0) + (2 * 2^1) + (3 * 2^2)
    // Coefficients passed as a template argument
    assert(polynomial!([3, 2, 1])(3) == 18); // (3 * 3^0) + (2 * 3^1) + (1 * 3^2)
}

public:



/// Computes the polynomial function c[0] * x^0 + c[1] * x^1 + c[2] * x^2 + ...
auto polynomial(T, C)(in T value, in C[] coefficients) if(
    isNumeric!T && isNumeric!C
){
    alias R = CommonType!(T, C);
    if(coefficients.length == 0){
        return R(0);
    }else{
        R result = cast(R) coefficients[$-1];
        for(int i = cast(int)(coefficients.length - 2); i >= 0; i--){
            result = (result * value) + coefficients[i];
        }
        return result;
    }
}

/// Ditto
auto polynomial(alias coefficients, T)(in T value) if(
    isNumeric!T && isArray!(typeof(coefficients))
){
    alias R = CommonType!(T, ArrayElementType!(typeof(coefficients)));
    static if(coefficients.length == 0){
        return R(0);
    }else{
        R result = cast(R) coefficients[$-1];
        for(int i = cast(int)(coefficients.length - 2); i >= 0; i--){
            result = (result * value) + coefficients[i];
        }
        return result;
    }
}



unittest{
    assert(polynomial(1, new int[0]) == 0);
    assert(polynomial!(new int[0])(1) == 0);
    assert(polynomial(50, [2]) == 2);
    assert(polynomial!([2])(50) == 2);
    assert(polynomial(1, [1, 2, 3]) == 6);
    assert(polynomial!([1, 2, 3])(1) == 6);
    assert(polynomial(2, [0, 1, 2, 3]) == 34);
    assert(polynomial!([0, 1, 2, 3])(2) == 34);
}

