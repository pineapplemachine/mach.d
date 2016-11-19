module mach.text.parse.numeric.floats;

private:

import mach.math : fisnan, fisinf, fiszero;
import mach.math : fextractsgn;
import mach.traits : isFloatingPoint;
import mach.traits : validAsStringRange, IEEEFormatOf;
import mach.range : asrange, asarray, finiterangeof;
import mach.text.parse.numeric.exceptions;
import mach.text.parse.numeric.integrals : writeint;
import mach.text.parse.numeric.burger : dragon;

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
        /// The value will always be in the form `\d(.\d+)?e-?\d+`.
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
    string NegNaNLiteral = "nan";
    /// What to output when the input is positive infinity.
    string PosInfLiteral = "inf";
    /// What to output when the input is negative infinity.
    string NegInfLiteral = "-inf";
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
        return value.fextractsgn ? settings.PosNaNLiteral : settings.NegNaNLiteral;
    }else if(value.fisinf){
        return value > 0 ? settings.PosInfLiteral : settings.NegInfLiteral;
    }else if(value.fiszero){
        static if(settings.exponentsetting is settings.ExponentSetting.Always){
            return zero() ~ "e0";
        }else{
            return zero();
        }
    }else{
        auto result = dragon(cast(double) value);
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
        if(k+1 < digits.length){
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



/// Parse a string representing a floating point number.
/// Throws a NumberParseException upon failure.
/// Liable to give incorrect results in the case of inordinately large
/// integral, fraction, or exponent values.
auto parsefloat(T = double, S)(auto ref S str) if(
    isFloatingPoint!T && validAsStringRange!S
){
    auto range = str.asrange;
    // TODO
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
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
}
unittest{
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
