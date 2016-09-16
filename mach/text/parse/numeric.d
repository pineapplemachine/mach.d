module mach.text.parse.numeric;

private:

import std.traits : Unqual;
import std.uni : Grapheme, byGrapheme;
//import std.bitmanip : FloatRep, DoubleRep; // TODO: Use this
import std.math : pow;
import mach.traits : isString;
import mach.range : contains, all, indexof, walklength, asrange;

public:



/// Exception raised when a number fails to parse.
class NumberParseException: Exception{
    static enum Reason{
        EmptyString,
        NoDigits,
        InvalidChar,
        MultDecimals,
        MalformedExp,
    }
    
    Reason reason;
    
    this(Reason reason, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse string as number: " ~ reasonname(reason), file, line, next);
        this.reason = reason;
    }
    
    static string reasonname(in Reason reason){
        final switch(reason){
            case Reason.EmptyString: return "Empty string.";
            case Reason.NoDigits: return "No digits in string.";
            case Reason.InvalidChar: return "Encountered invalid character.";
            case Reason.MultDecimals: return "Multiple decimal points.";
            case Reason.MalformedExp: return "Malformed exponent.";
        }
    }
    
    static void enforce(T)(auto ref T cond, Reason reason){
        if(!cond) throw new typeof(this)(reason);
    }
    static void enforceempty(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.EmptyString);
    }
    static void enforcedigits(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.NoDigits);
    }
    static void enforceinvalid(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.InvalidChar);
    }
    static void enforcedecimals(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.MultDecimals);
    }
}



/// Settings struct used to define behavior of parsing functions.
struct NumberParseSettings{
    static enum NumberParseSettings Default = {
        digits: "0123456789"d,
    };
    
    /// Allowed digits, in ascending order of value.
    dstring digits = "0123456789"d;
    /// Allowed signs.
    dstring signs = "+-"d;
    /// Signs indicating a value is negative.
    dstring negate = "-"d;
    /// Allowed decimal points.
    dstring decimals = "."d;
    /// Allowed exponent signifiers.
    dstring exponents = "eE"d;
    
    /// Get whether some character is a digit.
    bool isdigit(in dchar ch) const @safe{
        return this.digits.contains(ch);
    }
    /// Get the index of a digit, which also represents its value.
    auto getdigit(in dchar ch) const @safe{
        return this.digits.indexof(ch);
    }
    /// Get the number of digits, which also represents the numeric base.
    @property auto base() const @safe{
        return this.digits.length;
    }
    /// Get whether some character is a sign.
    bool issign(in dchar ch) const @safe{
        return this.signs.contains(ch);
    }
    /// Get whether some character is a negation sign.
    bool isneg(in dchar ch) const @safe{
        return this.negate.contains(ch);
    }
    /// Get whether some character is a decimal point.
    bool isdecimal(in dchar ch) const @safe{
        return this.decimals.contains(ch);
    }
    /// Get whether some character is an exponent signifier.
    bool isexp(in dchar ch) const @safe{
        return this.exponents.contains(ch);
    }
}



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



/// Parse a string representing an integer.
/// Throws a NumberParseException upon failure.
/// Does not check for under/overflow.
auto parseintegral(
    NumberParseSettings settings = NumberParseSettings.Default, T = long, S
)(auto ref S str) if(isString!S){
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
)(auto ref S str) if(isString!S){
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
    auto base = settings.base;
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
            value *= pow(10, exponent);
        }else{
            value /= pow(10, -exponent);
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
