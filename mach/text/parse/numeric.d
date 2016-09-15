module mach.text.parse.numeric;

private:

import std.traits : Unqual;
import std.uni : Grapheme, byGrapheme;
//import std.bitmanip : FloatRep, DoubleRep; // TODO: Use this
import std.math : pow;
import mach.error : ThrowableMixin;
import mach.traits : isString;
import mach.range : contains, all, indexof, walklength, asrange;

public:



/// Exception raised when a number fails to parse.
class NumericParseException: Exception{
    mixin ThrowableMixin!("Failed to parse string as number.");
    static void enforce(T)(
        T condition, size_t line = __LINE__, string file = __FILE__
    ){
        if(!condition) throw new typeof(this)(line, file);
    }
    static void enforce(T)(
        T condition, string message, size_t line = __LINE__, string file = __FILE__
    ){
        if(!condition) throw new typeof(this)(
            "Failed to parse string as number: " ~ message, null, line, file
        );
    }
}



/// Settings struct used to define behavior of parsing functions.
struct NumericParseSettings{
    static enum NumericParseSettings Default = {
        unicode: false,
        digits: "0123456789",
        signs: "+-",
        negate: "-",
        decimals: ".",
        exponents: "eE",
    };
    
    /// Whether digits may be unicode characters, alternative is to consider
    /// inputs as narrow strings.
    bool unicode = false;
    /// Allowed digits, in ascending order of value.
    string digits = "0123456789";
    /// Allowed signs.
    string signs = "+-";
    /// Signs indicating a value is negative.
    string negate = "-";
    /// Allowed decimal points.
    string decimals = ".";
    /// Allowed exponent signifiers.
    string exponents = "eE";
    
    /// Get whether some character is a digit.
    bool isdigit(in char ch) const @safe{
        return this.digits.contains(ch);
    }
    /// ditto
    bool isdigit(in Grapheme grapheme) const @safe{
        return this.digits.byGrapheme.contains(grapheme);
    }
    /// Get the index of a digit, which also represents its value.
    auto getdigit(in char ch) const @safe{
        return this.digits.indexof(ch);
    }
    /// ditto
    auto getdigit(in Grapheme grapheme) const @safe{
        return this.digits.byGrapheme.indexof(grapheme);
    }
    /// Get the number of digits, which also represents the numeric base.
    @property auto base() const @safe{
        if(this.unicode){
            return this.digits.byGrapheme.walklength;
        }else{
            return this.digits.length;
        }
    }
    /// Get whether some character is a sign.
    bool issign(in char ch) const @safe{
        return this.signs.contains(ch);
    }
    /// ditto
    bool issign(in Grapheme grapheme) const @safe{
        return this.signs.byGrapheme.contains(grapheme);
    }
    /// Get whether some character is a negation sign.
    bool isneg(in char ch) const @safe{
        return this.negate.contains(ch);
    }
    /// ditto
    bool isneg(in Grapheme grapheme) const @safe{
        return this.negate.byGrapheme.contains(grapheme);
    }
    /// Get whether some character is a decimal point.
    bool isdecimal(in char ch) const @safe{
        return this.decimals.contains(ch);
    }
    /// ditto
    bool isdecimal(in Grapheme grapheme) const @safe{
        return this.decimals.byGrapheme.contains(grapheme);
    }
    /// Get whether some character is an exponent signifier.
    bool isexp(in char ch) const @safe{
        return this.exponents.contains(ch);
    }
    /// ditto
    bool isexp(in Grapheme grapheme) const @safe{
        return this.exponents.byGrapheme.contains(grapheme);
    }
}



/// Utility function used by things in this module.
private bool isintegralrange(NumericParseSettings settings, R)(auto ref R range){
    if(range.empty) return false;
    if(settings.issign(range.front)){
        range.popFront();
        if(range.empty) return false;
    }
    return range.all!(ch => settings.isdigit(ch));
}



/// Get whether a string represents an integral.
/// The first character may be '-' or '+'. All following characters must be
/// digits, by default 0-9.
/// To be considered valid as an integral, the string must be non-null and at
/// least one character long.
bool isintegralstring(
    NumericParseSettings settings = NumericParseSettings.Default, S
)(auto ref S str) if(isString!S){
    static if(settings.unicode){
        auto range = str.byGrapheme;
    }else{
        auto range = str.asrange;
    }
    return isintegralrange!settings(range);
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
    NumericParseSettings settings = NumericParseSettings.Default, S
)(auto ref S str) if(isString!S){
    static if(settings.unicode){
        auto range = str.byGrapheme;
    }else{
        auto range = str.asrange;
    }
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
                return isintegralrange!settings(range);
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



/// Utility function used by things in this module.
private auto parseintegralrange(NumericParseSettings settings, T, R)(auto ref R range){
    NumericParseException.enforce(!range.empty, "Empty string.");
    bool negate = false;
    if(settings.issign(range.front)){
        negate = settings.isneg(range.front);
        range.popFront();
        NumericParseException.enforce(!range.empty, "No digits present.");
    }
    auto base = settings.base;
    Unqual!T value;
    while(!range.empty){
        auto digit = settings.getdigit(range.front);
        NumericParseException.enforce(digit >= 0, "Invalid digit.");
        value *= base;
        value += digit;
        range.popFront();
    }
    return cast(T)(negate ? -value : value);
}



/// Parse a string representing an integer.
/// Throws a NumericParseException upon failure.
/// Does not check for under/overflow.
auto parseintegral(
    NumericParseSettings settings = NumericParseSettings.Default, T = long, S
)(auto ref S str) if(isString!S){
    static if(settings.unicode){
        auto range = str.byGrapheme;
    }else{
        auto range = str.asrange;
    }
    return parseintegralrange!(settings, T)(range);
}



/// Parse a string representing a floating point number.
/// Throws a NumericParseException upon failure.
/// Liable to give incorrect results in the case of inordinately large
/// integral, fraction, or exponent values.
auto parsefloat(
    NumericParseSettings settings = NumericParseSettings.Default, T = double, S
)(auto ref S str) if(isString!S){
    static if(settings.unicode){
        auto range = str.byGrapheme;
    }else{
        auto range = str.asrange;
    }
    NumericParseException.enforce(!range.empty, "Empty string.");
    // Determine sign
    bool negate = false;
    if(settings.issign(range.front)){
        negate = settings.isneg(range.front);
        range.popFront();
        NumericParseException.enforce(!range.empty, "No digits present.");
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
            NumericParseException.enforce(!decimal, "Multiple decimal points.");
            decimal = true;
        }else if(settings.isexp(ch)){
            NumericParseException.enforce(nondecimal, "Exponent without multiplier.");
            range.popFront();
            exponent = parseintegralrange!(settings, long)(range);
            hasexp = true;
            break;
        }else{
            auto digit = settings.getdigit(range.front);
            NumericParseException.enforce(digit >= 0, "Invalid digit.");
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
    NumericParseException.enforce(nondecimal, "Decimal present but no digits.");
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
    void IsIntegralTests(alias func, bool uni)(){
        enum NumericParseSettings settings = {
            unicode: uni
        };
        test(func!settings("0"));
        test(func!settings("10"));
        test(func!settings("1234567890"));
        test(func!settings("+10"));
        test(func!settings("-10"));
        testf(func!settings(""));
        testf(func!settings(" "));
        testf(func!settings("a"));
        testf(func!settings("+"));
        testf(func!settings("-"));
        testf(func!settings("+-"));
        testf(func!settings("++"));
        testf(func!settings("--"));
        testf(func!settings("+a"));
        testf(func!settings("1+"));
        testf(func!settings("1-"));
    }
    void IsFloatTests(alias func, bool uni)(){
        enum NumericParseSettings settings = {
            unicode: uni
        };
        IsIntegralTests!(func, uni);
        test(func!settings("0.0"));
        test(func!settings("0."));
        test(func!settings(".0"));
        test(func!settings("10.10"));
        test(func!settings("1234567890.1234567890"));
        test(func!settings("+0.0"));
        test(func!settings("-0.0"));
        test(func!settings("+.0"));
        test(func!settings("+0."));
        test(func!settings("1e1"));
        test(func!settings("1E1"));
        test(func!settings("1E+1"));
        test(func!settings("1e+1"));
        test(func!settings("1e-1"));
        test(func!settings(".1e-1"));
        test(func!settings("1.e-1"));
        testf(func!settings("."));
        testf(func!settings(".."));
        testf(func!settings("1.."));
        testf(func!settings("1.0."));
        testf(func!settings("e"));
        testf(func!settings("e10"));
        testf(func!settings(".e10"));
        testf(func!settings("1e+"));
        testf(func!settings("1e-"));
        testf(func!settings("1e+1.0"));
    }
    void IsUnicodeTests(alias func)(){
        enum NumericParseSettings settings = {
            unicode: true,
            digits: "0π"
        };
        test(func!settings("0"));
        test(func!settings("π"));
        test(func!settings("0π"));
        test(func!settings("+0π"));
        test(func!settings("-0π"));
        testf(func!settings(""));
        testf(func!settings(" "));
        testf(func!settings("+"));
        testf(func!settings("-"));
        testf(func!settings("x"));
    }
    void ParseIntegralTests(alias func, bool uni)(){
        enum NumericParseSettings settings = {
            unicode: uni
        };
        testeq(func!settings("0"), 0);
        testeq(func!settings("100"), 100);
        testeq(func!settings("1234567890"), 1234567890);
        testeq(func!settings("+1"), +1);
        testeq(func!settings("-1"), -1);
        fail({func!settings("");});
        fail({func!settings(" ");});
        fail({func!settings("+");});
        fail({func!settings("-");});
        fail({func!settings("++");});
        fail({func!settings("+a");});
        fail({func!settings("0a");});
    }
    void ParseFloatTests(alias func, bool uni)(){
        enum NumericParseSettings settings = {
            unicode: uni
        };
        testeq(func!settings("0.0"), 0.0);
        testeq(func!settings("100.0"), 100.0);
        testeq(func!settings("1.0"), 1.0);
        testeq(func!settings("1."), 1.0);
        testeq(func!settings(".1"), 0.1);
        testeq(func!settings("1.1"), 1.1);
        testeq(func!settings("+1.0"), +1.0);
        testeq(func!settings("-1.0"), -1.0);
        testeq(func!settings("12345.67890"), 12345.67890);
        testeq(func!settings("1e10"), 1e10);
        testeq(func!settings("1e+10"), 1e+10);
        testeq(func!settings("1e-10"), 1e-10);
        fail({func!settings(".");});
        fail({func!settings("..");});
        fail({func!settings("1..");});
        fail({func!settings("1.0.");});
        fail({func!settings("e");});
        fail({func!settings("e10");});
        fail({func!settings(".e10");});
        fail({func!settings("1e+");});
        fail({func!settings("1e-");});
        fail({func!settings("1e+1.0");});
    }
}
unittest{
    tests("String represents number", {
        tests("Integral", {
            tests("ASCII", {
                IsIntegralTests!(isintegralstring, false);
            });
            tests("Unicode", {
                IsIntegralTests!(isintegralstring, true);
                IsUnicodeTests!isintegralstring;
            });
        });
        tests("Float", {
            tests("ASCII", {
                IsFloatTests!(isfloatstring, false);
            });
            tests("Unicode", {
                IsFloatTests!(isfloatstring, true);
                IsUnicodeTests!isfloatstring;
            });
        });
    });
}
unittest{
    tests("Parse numbers", {
        tests("Integral", {
            tests("ASCII", {
                ParseIntegralTests!(parseintegral, false);
            });
            tests("Unicode", {
                ParseIntegralTests!(parseintegral, true);
                //ParseUnicodeTests!parseintegral; // TODO
            });
        });
        tests("Float", {
            tests("ASCII", {
                ParseFloatTests!(parsefloat, false);
            });
            tests("Unicode", {
                ParseFloatTests!(parsefloat, true);
                //ParseUnicodeTests!parsefloat; // TODO
            });
        });
    });
}
