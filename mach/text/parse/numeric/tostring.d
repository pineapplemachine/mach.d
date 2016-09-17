module mach.text.parse.numeric.tostring;

private:

import std.traits : Unqual, isNumeric, isFloatingPoint;
import mach.range : retro, join, map, asarray;
import mach.text.utf : utfencode, UTFEncodePoint;
import mach.text.parse.numeric.settings;

public:



/// Build a string representation of an integral number, or the integral
/// portion of a floating point number.
auto integralstr(
    NumberParseSettings settings = NumberParseSettings.Default, N
)(N number) if(isNumeric!N){
    static if(isFloatingPoint!N){
        long n = cast(long) number;
    }else{
        auto n = cast(Unqual!N) number;
    }
    if(n == 0){
        return settings.zero.utfencode.toString();
    }else{
        immutable auto base = settings.base;
        UTFEncodePoint!char[] points;
        bool negative = n < 0;
        if(negative) n = cast(N) -n;
        while(n > 0){
            points ~= settings.digits[cast(size_t)(n % base)].utfencode;
            n /= base;
        }
        string str = points.retro.map!(e => e.toString()).join.asarray;
        return negative ? settings.neg.utfencode.toString() ~ str : str;
    }
}



/// Convenience function for stringifying an integral as a hex number.
auto hexstr(N)(N number) if(isNumeric!N){
    return integralstr!(NumberParseSettings.Hex)(number);
}

/// Convenience function for stringifying an integral as a binary number.
auto binstr(N)(N number) if(isNumeric!N){
    return integralstr!(NumberParseSettings.Binary)(number);
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Numbers as strings", {
        tests("Integral", {
            tests("Decimal", {
                testeq(integralstr(0), "0");
                testeq(integralstr(-0), "0");
                testeq(integralstr(1), "1");
                testeq(integralstr(-1), "-1");
                testeq(integralstr(100), "100");
                testeq(integralstr(-100), "-100");
                testeq(integralstr(1234567890), "1234567890");
            });
            tests("Hexadecimal", {
                alias hex = NumberParseSettings.Hex;
                testeq(integralstr!hex(0x0), "0");
                testeq(integralstr!hex(-0x0), "0");
                testeq(integralstr!hex(0x1), "1");
                testeq(integralstr!hex(-0x1), "-1");
                testeq(integralstr!hex(0x100), "100");
                testeq(integralstr!hex(-0x100), "-100");
                testeq(integralstr!hex(0x1234567890), "1234567890");
                testeq(integralstr!hex(0xabcdef), "abcdef");
                testeq(integralstr!hex(255), "ff");
            });
        });
        tests("Convenience", {
            testeq(255.hexstr, "ff");
            testeq(7.binstr, "111");
        });
    });
}
