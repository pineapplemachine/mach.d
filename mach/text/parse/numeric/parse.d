module mach.text.parse.numeric.parse;

private:

//import std.bitmanip : FloatRep, DoubleRep; // TODO: Use this
import mach.traits : Unqual, isNumeric, isFloatingPoint;
import mach.traits : validAsStringRange;
import mach.range : asrange;
import mach.text.parse.numeric.exceptions;
import mach.text.parse.numeric.settings;

public:



/// Parse a string representing an integer.
/// Throws a NumberParseException upon failure.
/// Does not check for under/overflow.
auto parseintegral(
    NumberParseSettings settings = NumberParseSettings.Default, T = long, S
)(auto ref S str) if(isNumeric!T && validAsStringRange!S){
    auto range = str.asrange;
    NumberParseException.enforceempty(!range.empty);
    bool negate = false;
    if(settings.issign(range.front)){
        negate = settings.isneg(range.front);
        range.popFront();
        NumberParseException.enforcedigits(!range.empty);
    }
    auto base = settings.base;
    Unqual!T value;
    while(!range.empty){
        auto digit = settings.getdigit(range.front);
        NumberParseException.enforceinvalid(digit >= 0);
        value *= base;
        value += digit;
        range.popFront();
    }
    return cast(T)(negate ? -value : value);
}



/// Parse a string representing a floating point number.
/// Throws a NumberParseException upon failure.
/// Liable to give incorrect results in the case of inordinately large
/// integral, fraction, or exponent values.
auto parsefloat(
    NumberParseSettings settings = NumberParseSettings.Default, T = double, S
)(auto ref S str) if(isFloatingPoint!T && validAsStringRange!S){
    auto range = str.asrange;
    NumberParseException.enforceempty(!range.empty);
    // Determine sign
    bool negate = false;
    if(settings.issign(range.front)){
        negate = settings.isneg(range.front);
        range.popFront();
        NumberParseException.enforcedigits(!range.empty);
    }
    // Parse the rest
    immutable auto base = settings.base;
    ulong integral;
    ulong fraction;
    ulong maxfraction = 1;
    long exponent = 1;
    bool hasexp = false;
    bool decimal = false;
    bool nondecimal = false;
    while(!range.empty){
        auto ch = range.front;
        if(settings.isdecimal(ch)){
            NumberParseException.enforcedecimals(!decimal);
            decimal = true;
        }else if(settings.isexp(ch)){
            NumberParseException.enforcedigits(nondecimal);
            range.popFront();
            try{
                exponent = parseintegral!(settings, long)(range);
            }catch(NumberParseException exception){
                throw new NumberParseException(
                    NumberParseException.Reason.MalformedExp, exception
                );
            }
            hasexp = true;
            break;
        }else{
            auto digit = settings.getdigit(range.front);
            NumberParseException.enforceinvalid(digit >= 0);
            if(!decimal){
                integral *= base;
                integral += digit;
            }else{
                fraction *= base;
                fraction += digit;
                maxfraction *= base;
            }
            nondecimal = true;
        }
        range.popFront();
    }
    NumberParseException.enforcedigits(nondecimal);
    // Turn it into a floating point number
    // TODO: Set exponent and mantissa bits manually
    Unqual!T value;
    value = fraction;
    value /= maxfraction;
    value += integral;
    if(hasexp){
        if(exponent > 0){
            value *= base ^^ exponent;
        }else{
            value /= base ^^ -exponent;
        }
    }
    return cast(T)(negate ? -value : value);
}



version(unittest){
    private:
    import mach.error.unit;
    alias Reason = NumberParseException.Reason;
    void failbecause(Reason reason, in void delegate() dg){
        fail(
            (e){
                auto ep = (cast(NumberParseException) e);
                return ep !is null && ep.reason == reason;
            }, dg
        );
    }
    void ParseIntegralTests(alias func)(){
        testeq(func("0"), 0);
        testeq(func("100"), 100);
        testeq(func("1234567890"), 1234567890);
        testeq(func("+1"), +1);
        testeq(func("-1"), -1);
        failbecause(Reason.EmptyString, {func("");});
        failbecause(Reason.NoDigits, {func("+");});
        failbecause(Reason.NoDigits, {func("-");});
        failbecause(Reason.InvalidChar, {func("a");});
        failbecause(Reason.InvalidChar, {func("+a");});
        failbecause(Reason.InvalidChar, {func("0a");});
        // Really, either NoDigits or InvalidChar would be accurate
        fail({func("++");});
    }
    void ParseFloatTests(alias func)(){
        testeq(func("0.0"), 0.0);
        testeq(func("100.0"), 100.0);
        testeq(func("1.0"), 1.0);
        testeq(func("1."), 1.0);
        testeq(func(".1"), 0.1);
        testeq(func("1.1"), 1.1);
        testeq(func("+1.0"), +1.0);
        testeq(func("-1.0"), -1.0);
        testeq(func("12345.67890"), 12345.67890);
        testeq(func("1e10"), 1e10);
        testeq(func("1e+10"), 1e+10);
        testeq(func("1e-10"), 1e-10);
        failbecause(Reason.NoDigits, {func(".");});
        failbecause(Reason.NoDigits, {func("e");});
        failbecause(Reason.NoDigits, {func(".e");});;
        failbecause(Reason.NoDigits, {func(".e10");});;
        failbecause(Reason.MultDecimals, {func("1..");});
        failbecause(Reason.MultDecimals, {func("1.0.");});
        failbecause(Reason.MalformedExp, {func("1e+");});
        failbecause(Reason.MalformedExp, {func("1e-");});
        failbecause(Reason.MalformedExp, {func("1ex");});
        failbecause(Reason.MalformedExp, {func("1e1.0");});
        // Really, either NoDigits or MultDecimals would be accurate
        fail({func("..");});
    }
    void ParseUnicodeTests(alias func)(){
        enum NumberParseSettings settings = {digits: "0π"d};
        testeq(func!settings("0"d), 0);
        testeq(func!settings("π"d), 1);
        testeq(func!settings("0π"d), 1);
        testeq(func!settings("π0"d), 2);
        testeq(func!settings("ππ"d), 3);
        testeq(func!settings("+0π"d), +1);
        testeq(func!settings("-0π"d), -1);
        fail({func!settings(""d);});
        fail({func!settings(" "d);});
        fail({func!settings("+"d);});
        fail({func!settings("-"d);});
        fail({func!settings("x"d);});
    }
}
unittest{
    tests("Parse numbers", {
        tests("Integral", {
            ParseIntegralTests!parseintegral;
            ParseUnicodeTests!parseintegral;
        });
        tests("Float", {
            ParseIntegralTests!parsefloat;
            ParseFloatTests!parsefloat;
            ParseUnicodeTests!parsefloat;
        });
    });
}
