module mach.text.parse.numeric.stringis;

private:

import mach.traits : isString;
import mach.range : all, asrange;
import mach.text.parse.numeric.settings;

public:



/// Get whether a string represents an integral.
/// The first character may be '-' or '+'. All following characters must be
/// digits, by default 0-9.
/// To be considered valid as an integral, the string must be non-null and at
/// least one character long.
bool isintegralstring(
    NumberParseSettings settings = NumberParseSettings.Default, S
)(auto ref S str) if(isString!S){
    auto range = str.asrange;
    if(range.empty) return false;
    if(settings.issign(range.front)){
        range.popFront();
        if(range.empty) return false;
    }
    return range.all!(ch => settings.isdigit(ch));
}



/// Get whether a string represents a floating point number.
/// The first character may be '-' or '+'. Following numbers may be digits,
/// there may be one '.' among the digits, but there must be at least one
/// other digit.
/// The string may end with an exponent, e.g. "e+10", 'e' being case-insensitive
/// the sign being option, and the number being an integer.
/// To be considered valid as a floating point number, the string must be
/// non-null and at least one character long.
bool isfloatstring(
    NumberParseSettings settings = NumberParseSettings.Default, S
)(auto ref S str) if(isString!S){
    auto range = str.asrange;
    if(range.empty) return false;
    if(settings.issign(range.front)){
        range.popFront();
        if(range.empty) return false;
    }
    bool decimal = false;
    bool nondecimal = false;
    while(!range.empty){
        auto ch = range.front;
        if(settings.isdecimal(ch)){
            if(decimal) return false;
            decimal = true;
        }else if(settings.isexp(ch)){
            if(nondecimal){
                range.popFront();
                return isintegralstring!settings(range);
            }else{
                return false;
            }
        }else if(!settings.isdigit(ch)){
            return false;
        }else{
            nondecimal = true;
        }
        range.popFront();
    }
    return nondecimal;
}



version(unittest){
    private:
    import mach.error.unit;
    void IsIntegralTests(alias func)(){
        test(func("0"));
        test(func("10"));
        test(func("1234567890"));
        test(func("+10"));
        test(func("-10"));
        testf(func(""));
        testf(func(" "));
        testf(func("a"));
        testf(func("+"));
        testf(func("-"));
        testf(func("+-"));
        testf(func("++"));
        testf(func("--"));
        testf(func("+a"));
        testf(func("1+"));
        testf(func("1-"));
    }
    void IsFloatTests(alias func)(){
        IsIntegralTests!(func);
        test(func("0.0"));
        test(func("0."));
        test(func(".0"));
        test(func("10.10"));
        test(func("1234567890.1234567890"));
        test(func("+0.0"));
        test(func("-0.0"));
        test(func("+.0"));
        test(func("+0."));
        test(func("1e1"));
        test(func("1E1"));
        test(func("1E+1"));
        test(func("1e+1"));
        test(func("1e-1"));
        test(func(".1e-1"));
        test(func("1.e-1"));
        testf(func("."));
        testf(func(".."));
        testf(func("1.."));
        testf(func("1.0."));
        testf(func("e"));
        testf(func("e10"));
        testf(func(".e10"));
        testf(func("1e+"));
        testf(func("1e-"));
        testf(func("1e+1.0"));
    }
    void IsUnicodeTests(alias func)(){
        enum NumberParseSettings settings = {digits: "0π"d};
        test(func!settings("0"d));
        test(func!settings("π"d));
        test(func!settings("0π"d));
        test(func!settings("+0π"d));
        test(func!settings("-0π"d));
        testf(func!settings(""d));
        testf(func!settings(" "d));
        testf(func!settings("+"d));
        testf(func!settings("-"d));
        testf(func!settings("x"d));
    }
}
unittest{
    tests("String represents number", {
        tests("Integral", {
            IsIntegralTests!isintegralstring;
            IsUnicodeTests!isintegralstring;
        });
        tests("Float", {
            IsIntegralTests!isfloatstring;
            IsFloatTests!isfloatstring;
            IsUnicodeTests!isfloatstring;
        });
    });
}
