module mach.text.numeric.floats;

private:

import mach.math.floats : fisnan, fisinf, fiszero;
import mach.math.floats : fextractsgn, fcomposedec;
import mach.math.ints : intfmaoverflow;
import mach.traits : IEEEFormatOf, isFloatingPoint, isString, ElementType;
import mach.range : asrange, asarray, finiterangeof;
import mach.text.numeric.exceptions;
import mach.text.numeric.integrals : writeint;
import mach.text.numeric.burger : dragon;

/++ Docs

This module implements the `writefloat` and `parsefloat` functions, which can
be used to serialize and deserialize floating point values as human-readable
strings in decimal notation.

The `writefloat` function optionally accepts a `WriteFloatSettings` object
as a template parameter, which defines aspects of behavior such as what to
output when the value is infinity or NaN, how to handle very large and
small inputs, and whether to always output a trailing `.0` even for integer
values.

The `parsefloat` function throws a `NumberParseException` when the input was
malformed.
Note that the `parsefloat` function does not accept string literals intended
to represent NaN or infinity; it parses only numeric literals.

+/

unittest{ /// Example
    assert(writefloat(0) == "0");
    assert(writefloat(123.456) == "123.456");
    assert(writefloat(double.infinity) == "infinity");
}

unittest{ /// Example
    enum WriteFloatSettings settings = {
        PosInfLiteral: "positive infinity",
        NegInfLiteral: "negative infinity"
    };
    assert(writefloat!settings(double.infinity) == "positive infinity");
    assert(writefloat!settings(-double.infinity) == "negative infinity");
}

unittest{ /// Example
    assert("1234.5".parsefloat!double == double(1234.5));
    assert("678e9".parsefloat!double == double(678e9));
}

unittest{ /// Example
    import mach.error.mustthrow : mustthrow;
    mustthrow!NumberParseException({
        "malformed input".parsefloat!double;
    });
}

public:



/// Settings for float stringification behavior.
struct WriteFloatSettings{
    static enum WriteFloatSettings Default = WriteFloatSettings();
    
    static enum DefaultExponentThreshold = 12;
    
    static enum ExponentSetting{
        /// Never output an exponent when forming a string;
        /// use as many zeros as is necessary. (Even when that's a lot.)
        Never,
        /// Always output an exponent when forming a string;
        /// The value will always be in the form `\d(\.\d+)?e-?\d+`.
        Always,
        /// When the number of preceding or trailing zeros that would need
        /// to be included to represent a value exceeds the threshold described
        /// by a settings object's `exponentthreshold` attribute, output an
        /// exponent when forming the string. Otherwise, do not use an exponent.
        Threshold
    }
    
    /// What to output when the input is positive NaN.
    string PosNaNLiteral = "nan";
    /// What to output when the input is negative NaN.
    string NegNaNLiteral = "-nan";
    /// What to output when the input is positive infinity.
    string PosInfLiteral = "infinity";
    /// What to output when the input is negative infinity.
    string NegInfLiteral = "-infinity";
    /// Whether to write a trailing ".0" when the value would otherwise be
    /// represented by an integral.
    bool trailingfraction = false;
    /// Setting for when, if ever, to use exponents to describe inputted
    /// values.
    ExponentSetting exponentsetting = ExponentSetting.Threshold;
    /// When `exponentsetting` is set to Threshold, this is the maximum number
    /// of leading or trailing zeros to allow before an exponent is used to
    /// represent the value instead.
    uint exponentthreshold = DefaultExponentThreshold;
}



string writefloat(
    WriteFloatSettings settings = WriteFloatSettings.Default
)(in double value){
    auto zero(){
        static if(settings.trailingfraction){
            return value.fextractsgn ? "-0.0" : "0.0";
        }else{
            return value.fextractsgn ? "-0" : "0";
        }
    }
    
    if(value.fisnan){
        return value.fextractsgn ? settings.NegNaNLiteral : settings.PosNaNLiteral;
    }else if(value.fisinf){
        return value > 0 ? settings.PosInfLiteral : settings.NegInfLiteral;
    }else if(value.fiszero){
        static if(settings.exponentsetting is settings.ExponentSetting.Always){
            return zero() ~ "e0";
        }else{
            return zero();
        }
    }else{
        immutable result = dragon(cast(double) value);
        if(result.sign){
            return '-' ~ writeunsignedfloat!settings(result.digits, result.k);
        }else{
            return writeunsignedfloat!settings(result.digits, result.k);
        }
    }
}

/// Used by `writefloat` implementation.
private string writeunsignedfloat(WriteFloatSettings settings)(
    in string digits, in int k
){
    string withexp(){
        if(digits.length == 1){
            static if(settings.trailingfraction){
                return digits ~ ".0e" ~ k.writeint;
            }else{
                return digits ~ 'e' ~ k.writeint;
            }
        }else{
            return digits[0] ~ "." ~ digits[1 .. $] ~ 'e' ~ k.writeint;
        }
    }
    string leadingz(){
        return cast(string)("0." ~ finiterangeof(-k - 1, '0').asarray ~ digits);
    }
    string trailingz(){
        immutable zeros = finiterangeof(1 + k - digits.length, '0').asarray;
        static if(settings.trailingfraction){
            return cast(string)(digits ~ zeros ~ ".0");
        }else{
            return cast(string)(digits ~ zeros);
        }
    }
    string placedec(){
        if(k + 1 < digits.length){
            return digits[0 .. k+1] ~ '.' ~ digits[k+1 .. $];
        }else{
            static if(settings.trailingfraction){
                return digits ~ ".0";
            }else{
                return digits;
            }
        }
    }
    
    static if(settings.exponentsetting is settings.ExponentSetting.Always){
        return withexp();
    }else static if(settings.exponentsetting is settings.ExponentSetting.Never){
        if(k < 0) return leadingz();
        else if(k < digits.length) return placedec();
        else return trailingz();
    }else{
        immutable threshold = settings.exponentthreshold;
        if(k < 0){
            return (-k - 1) > threshold ? withexp() : leadingz();
        }else if(k < digits.length){
            return placedec();
        }else{
            return (1 + k - digits.length) > threshold ? withexp() : trailingz();
        }
    }
}



private static enum ParseFloatState{
    IntegralInitial,
    IntegralSigned,
    Integral,
    FractionInitial,
    Fraction,
    ExponentInitial,
    ExponentSigned,
    Exponent,
}

/// Parse a string representing a floating point number.
/// Throws a NumberParseException upon failure.
/// When the mantissa of the input exceeds the accuracy storable by the
/// given floating point type, the least significant digits are ignored.
/// When the exponent is too large or small to store, the largest/smallest
/// possible exponent is used instead.
T parsefloat(T = double, S)(auto ref S str) if(
    isFloatingPoint!T && isString!S
){
    static const error = new NumberParseException();
    
    alias Mantissa = ulong;
    alias Exponent = uint;
    alias Char = ElementType!S;
    alias State = ParseFloatState;
    State state = State.IntegralInitial;
    
    // The most significant digits of the mantissa.
    Mantissa mantissa = 0;
    // Number of digits in the mantissa; can be less than the number in the string.
    uint mantdigits = 0;
    // Number of digits preceding the decimal point.
    uint decimal = 0;
    // Whether the mantissa is negative.
    bool mantnegative = false;
    // Whether the mantissa has overflowed.
    bool mantoverflow = false;
    
    /// Base 10 exponent.
    Exponent exponent = 0;
    // Whether the exponent is negative.
    bool expnegative = false;
    // Whether the exponent has overflowed.
    bool expoverflow = false;
    
    void addmantdigit(in Char ch){
        if(!mantoverflow){
            immutable result = intfmaoverflow(mantissa, 10, ch - '0');
            if(result.overflow){
                mantoverflow = true;
            }else{
                mantissa = result.value;
                mantdigits++;
            }
        }
    }
    auto addexpdigit(in Char ch){
        if(!expoverflow){
            immutable result = intfmaoverflow(exponent, 10, ch - '0');
            if(result.overflow){
                expoverflow = true;
            }else{
                exponent = result.value;
            }
        }
    }
    
    foreach(ch; str){
        if(ch >= '0' && ch <= '9'){
            final switch(state){
                case State.IntegralInitial:
                    goto case;
                case State.IntegralSigned:
                    state = State.Integral;
                    goto case;
                case State.Integral:
                    addmantdigit(ch);
                    decimal++;
                    break;
                case State.FractionInitial:
                    state = State.Fraction;
                    goto case;
                case State.Fraction:
                    addmantdigit(ch);
                    break;
                case State.ExponentInitial:
                    goto case;
                case State.ExponentSigned:
                    state = State.Exponent;
                    goto case;
                case State.Exponent:
                    addexpdigit(ch);
                    break;
            }
        }else if(ch == '.'){
            if(
                state is State.IntegralInitial ||
                state is State.IntegralSigned ||
                state is State.Integral
            ){
                state = State.FractionInitial;
            }else{
                throw error;
            }
        }else if(ch == '-'){
            if(state is State.IntegralInitial){
                mantnegative = true;
                state = State.IntegralSigned;
            }else if(state is State.ExponentInitial){
                expnegative = true;
                state = State.ExponentSigned;
            }else{
                throw error;
            }
        }else if(ch == '+'){
            if(state is State.IntegralInitial){
                state = State.IntegralSigned;
            }else if(state is State.ExponentInitial){
                state = State.ExponentSigned;
            }else{
                throw error;
            }
        }else if(ch == 'e' || ch == 'E'){
            if(
                state is State.Integral ||
                state is State.FractionInitial ||
                state is State.Fraction
            ){
                state = State.ExponentInitial;
            }else{
                throw error;
            }
        }else{
            throw error;
        }
    }
    
    if(
        mantdigits == 0 ||
        state is State.IntegralSigned ||
        state is State.ExponentInitial ||
        state is State.ExponentSigned
    ){
        throw error; // Unexpected EOF
    }else if(mantissa == 0){
        return mantnegative ? -T(0) : T(0);
    }else{
        immutable sexp = (
            (expnegative ? -(cast(int) exponent) : cast(int) exponent) +
            cast(int)(decimal - mantdigits)
        );
        return fcomposedec!T(mantnegative, mantissa, sexp);
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
    import mach.math.floats.compare : fidentical;
    import mach.error.mustthrow : mustthrow;
}

unittest{ // TODO: rewrite without using mach.test
    void commontests(WriteFloatSettings settings)(){
        testeq(writefloat!settings(double.infinity), settings.PosInfLiteral);
        testeq(writefloat!settings(-double.infinity), settings.NegInfLiteral);
        testeq(writefloat!settings(double.nan), settings.PosNaNLiteral);
        testeq(writefloat!settings(-double.nan), settings.NegNaNLiteral);
    }
    void testwrite(WriteFloatSettings settings, string literal)(){
        mixin(`double pvalue = ` ~ literal ~ `;`);
        testeq(pvalue.writefloat!settings, literal);
        mixin(`double nvalue = -` ~ literal ~ `;`);
        testeq(nvalue.writefloat!settings, '-' ~ literal);
    }
    tests("Write float", {
        enum string double_min = "2.2250738585072014e-305";
        enum string double_max = "1.7976931348623157e308";
        // No exponents, no trailing fraction
        {
            enum WriteFloatSettings settings = {
                trailingfraction: false,
                exponentsetting: WriteFloatSettings.ExponentSetting.Never
            };
            testeq((0.0).writefloat!settings, "0");
            testeq((-0.0).writefloat!settings, "-0");
            commontests!settings();
            foreach(str; Aliases!(
                "1", "0.1", "0.125", "10", "100", "1000",
                "123.456", "0.3333", "0.9999", "9001", "0.9001", "0.009001"
            )){
                testwrite!(settings, str)();
            }
        }
        // No exponents, always trailing fraction
        {
            enum WriteFloatSettings settings = {
                trailingfraction: true,
                exponentsetting: WriteFloatSettings.ExponentSetting.Never
            };
            commontests!settings();
            foreach(str; Aliases!(
                "0.0", "1.0", "0.1", "0.125", "10.0", "100.0", "1000.0",
                "123.456", "0.3333", "0.9999", "9001.0", "0.9001", "0.009001"
            )){
                testwrite!(settings, str)();
            }
        }
        // Always exponents, no trailing fraction
        {
            enum WriteFloatSettings settings = {
                trailingfraction: false,
                exponentsetting: WriteFloatSettings.ExponentSetting.Always
            };
            commontests!settings();
            foreach(str; Aliases!(
                "0e0", "1e0", "1.25e-1", "1e1", "1e2", "1e3",
                "1.23456e2", "3.333e-1", "9.999e-1", "9.001e3", "9.001e-1",
                "9.001e-3", "9.001e-4", double_min, double_max
            )){
                testwrite!(settings, str)();
            }
        }
        // Always exponents, always trailing fraction
        {
            enum WriteFloatSettings settings = {
                trailingfraction: true,
                exponentsetting: WriteFloatSettings.ExponentSetting.Always
            };
            commontests!settings();
            foreach(str; Aliases!(
                "0.0e0", "1.0e0", "1.25e-1", "1.0e1", "1.0e2", "1.0e3",
                "1.23456e2", "3.333e-1", "9.999e-1", "9.001e3", "9.001e-1", "9.001e-3"
            )){
                testwrite!(settings, str)();
            }
        }
        // Exponent threshold
        {
            enum WriteFloatSettings settings = {
                trailingfraction: false,
                exponentsetting: WriteFloatSettings.ExponentSetting.Threshold,
                exponentthreshold: 2
            };
            commontests!settings();
            foreach(str; Aliases!(
                "1", "0.1", "0.125", "10", "100", "1e3",
                "123.456", "0.3333", "0.9999", "9001", "0.9001", "0.009001",
                "9.001e-4", double_min, double_max
            )){
                testwrite!(settings, str)();
            }
        }
    });
}

unittest{ /// Write float special cases
    enum Settings = WriteFloatSettings.Default;
    assert((double.infinity).writefloat == Settings.PosInfLiteral);
    assert((-double.infinity).writefloat == Settings.NegInfLiteral);
    assert((double.nan).writefloat == Settings.PosNaNLiteral);
    assert((-double.nan).writefloat == Settings.NegNaNLiteral);
}

unittest{ /// Parse float
    alias numbers = Aliases!(
        "0.0", "0.0000", "000.0000000000000000000000000",
        "0.25", "0.025", "0.0005", "0.00000000000000005",
        "1", "1.0", "10", "10.0", "11", "11.1", "11.11", "1111.111111111111111",
        "2", "20", "200", "20000001", "123456", "123.456", "789.123456",
        "1e0", "1e1", "1e2", "1e3", "1e4", "1e5", "1e100", "1e200", "1e2000",
        "1e+0", "1e+1", "1e+2", "1e+3", "1e+4", "1e+5", "1e+100", "1e+200", "1e+2000",
        "1e-0", "1e-1", "1e-2", "1e-3", "1e-4", "1e-5", "1e-100", "1e-200", "1e-2000",
        "2e2", "123e4", "123456e7", "1.12313241e12", "1.1e-100", "111.111111111111e-100",
        "1e01", "01e01", ".01", ".0002"
    );
    foreach(numberstr; numbers){
        // Reals not included here because compiler and implementation output
        // occassionally differ, and which output is more accurate varies.
        foreach(T; Aliases!(double, float)){
            mixin(`T a = ` ~ numberstr ~ `L;`);
            mixin(`T b = -` ~ numberstr ~ `L;`);
            immutable parseda = parsefloat!T(numberstr);
            immutable parsedb = parsefloat!T(`+` ~ numberstr);
            immutable parsedc = parsefloat!T(`-` ~ numberstr);
            assert(fidentical(parseda, a));
            assert(fidentical(parsedb, a));
            assert(fidentical(parsedc, b));
        }
    }
}

unittest{ /// Parse floats with no digits after decimal
    assert(fidentical(parsefloat!double("15."), double(15)));
    assert(fidentical(parsefloat!double("-15."), double(-15)));
    assert(fidentical(parsefloat!double("15.e10"), double(15e10)));
    assert(fidentical(parsefloat!double("15.e-10"), double(15e-10)));
    assert(fidentical(parsefloat!double("15.E10"), double(15E10)));
    assert(fidentical(parsefloat!double("15.E-10"), double(15E-10)));
}

unittest{ /// Malformed parse inputs
    void bad(string str){
        mustthrow!NumberParseException({
            parsefloat!float(str);
        });
        mustthrow!NumberParseException({
            parsefloat!double(str);
        });
        mustthrow!NumberParseException({
            parsefloat!real(str);
        });
    }
    bad("");
    bad(".");
    bad(" ");
    bad("e");
    bad("E");
    bad("x");
    bad("xx");
    bad(".x");
    bad("x.");
    bad("x.x");
    bad("x0");
    bad("0x");
    bad("0-");
    bad("0+");
    bad("0-0");
    bad("0+0");
    bad("123e");
    bad("123E");
    bad("123e+");
    bad("123e-");
    bad("123e5.");
    bad("123E5.");
    bad("123ex");
    bad("123Ex");
    bad("123e0x");
    bad("123E0x");
}
