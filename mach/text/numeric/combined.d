module mach.text.numeric.combined;

private:

import mach.traits : isString, isNumeric, isIntegral;
import mach.text.numeric.floats : writefloat, parsefloat, WriteFloatSettings;
import mach.text.numeric.integrals : writeint, parseint;
import mach.range.compare : equals, canCompareIterablesEquality;

/++ Docs

This module implements the `parsenumber` and `writenumber` methods, which are
generic interfaces to the `parseint`, `parsefloat`, `writeint`, and `writefloat`
methods.
These methods accept either integers or floats as input, but do not offer the
same specialized configuration options as if the wrapped methods were called
directly.

Note that while the `parsefloat` method operates strictly upon numeric literals,
the `parsenumber` method, when parsing a floating point type, will recognize
the literals defined in the default `WriteFloatSettings` and return the special
values accordingly.

+/

unittest{ /// Example
    assert("100".parsenumber!int == 100);
    assert("256".parsenumber!ushort == 256);
    assert("1234.5".parsenumber!double == double(1234.5));
    assert("1e20".parsenumber!double == double(1e20));
}

unittest{ /// Example
    import mach.math.floats.properties : fisposinf, fisnan;
    assert("infinity".parsenumber!double.fisposinf);
    assert("nan".parsenumber!double.fisnan);
}

/++ Docs

The `parsenumber` method, like `parseint` and `parsefloat`, throws a
`NumberParseException` when the input was malformed.

+/

unittest{ /// Example
    import mach.error.mustthrow : mustthrow;
    mustthrow!NumberParseException({
        "some malformed input".parsenumber!int;
    });
}

public:



/// Parse either a float or an integer from a decimal string.
/// In most cases, the literals `infinity`, `-infinity`, `nan`, and `-nan`,
/// as defined by the default WriteFloatSettings, will be recognized.
auto parsenumber(T, S)(auto ref S str) if(isString!S && isNumeric!T){
    static if(isIntegral!T){
        return parseint!T(str);
    }else{
        static if(canCompareIterablesEquality!(S, string)){
            if(str.equals(WriteFloatSettings.Default.PosInfLiteral)){
                return T.infinity;
            }else if(str.equals(WriteFloatSettings.Default.NegInfLiteral)){
                return -T.infinity;
            }else if(str.equals(WriteFloatSettings.Default.PosNaNLiteral)){
                return T.nan;
            }else if(str.equals(WriteFloatSettings.Default.NegNaNLiteral)){
                return -T.nan;
            }else{
                return parsefloat!T(str);
            }
        }else{
            return parsefloat!T(str);
        }
    }
}

auto writenumber(T)(in T number) if(isNumeric!T){
    static if(isIntegral!T){
        return writeint(number);
    }else{
        return writefloat(number);
    }
}



private version(unittest){
    import mach.error.mustthrow : mustthrow;
    import mach.text.numeric.exceptions : NumberParseException;
    import mach.math.floats.extract : fextractsgn;
    import mach.math.floats.properties;
}

unittest{
    auto i = parsenumber!int("123");
    static assert(is(typeof(i) == int));
    assert(i == 123);
}

unittest{
    auto i = parsenumber!double("1.23");
    static assert(is(typeof(i) == double));
    assert(i == double(1.23));
}

unittest{
    enum Settings = WriteFloatSettings.Default;
    // Positive infinity
    assert(parsenumber!double(Settings.PosInfLiteral).fisposinf);
    // Negative infinity
    assert(parsenumber!double(Settings.NegInfLiteral).fisneginf);
    // Positive NaN
    auto posnan = parsenumber!double(Settings.PosNaNLiteral);
    assert(posnan.fisnan && !posnan.fextractsgn);
    // Negative NaN
    auto negnan = parsenumber!double(Settings.NegNaNLiteral);
    assert(negnan.fisnan && negnan.fextractsgn);
}

unittest{
    mustthrow!NumberParseException({
        "".parsenumber!int;
    });
    mustthrow!NumberParseException({
        "".parsenumber!double;
    });
}

unittest{
    assert(int(0).writenumber == "0");
    assert(int(1).writenumber == "1");
    assert(int(-1).writenumber == "-1");
    assert(int(12345).writenumber == "12345");
}

unittest{
    assert(double(0).writenumber == "0");
    assert(double(1).writenumber == "1");
    assert(double(-1).writenumber == "-1");
    assert(double(12345).writenumber == "12345");
    assert(double(123.456).writenumber == "123.456");
    assert(double(1.2e40).writenumber == "1.2e40");
}

unittest{
    enum Settings = WriteFloatSettings.Default;
    assert((double.infinity).writenumber == Settings.PosInfLiteral);
    assert((-double.infinity).writenumber == Settings.NegInfLiteral);
    assert((double.nan).writenumber == Settings.PosNaNLiteral);
    assert((-double.nan).writenumber == Settings.NegNaNLiteral);
}
