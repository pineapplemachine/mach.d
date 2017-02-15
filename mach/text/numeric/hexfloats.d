module mach.text.numeric.hexfloats;

private:

import mach.traits : IEEEFormatOf, isFloatingPoint, isString;
import mach.math.bits : pow2, pow2d;
import mach.math.floats : fisnan, fisinf, fiszero, fisnormal, fextractsexp;
import mach.math.floats : fextractsig, fextractsgn, fcomposeexp;
import mach.math.ints : intfmaoverflow;
import mach.text.numeric.exceptions;
import mach.text.numeric.integrals : writeint, writebin;
import mach.text.numeric.floats : WriteFloatSettings;

/++ Docs

The `writehexfloat` and `parsehexfloat` functions can be used to write and
parse floats in a hexadecimal format.
For a description of this format, see the
[D language documentation](https://dlang.org/spec/lex.html#floatliteral)
and the [C99 standard](http://c0x.coding-guidelines.com/6.4.4.2.html).

The `parsehexfloat` function accepts an optional template parameter indicating
the floating point type to parse, i.e. `float`, `double`, or `real`.
If no such parameter is provided, then the function returns a double by default.

+/

unittest{ /// Example
    assert(writehexfloat(0x1.23abcp10) == "0x1.23abcp10");
    assert(parsehexfloat!double("0x1.23abcp10") == double(0x1.23abcp10));
}

/++ Docs

`parsehexfloat` throws a `ParseNumberException` when it receives a malformed
input string.

+/

unittest{ /// Example
    import mach.error.mustthrow : mustthrow;
    mustthrow!NumberParseException({
        "malformed input".parsehexfloat;
    });
}

public:



struct WriteHexFloatSettings{
    static enum WriteHexFloatSettings Default = WriteHexFloatSettings();
    /// What to output when the input is positive NaN.
    string PosNaNLiteral = WriteFloatSettings.Default.PosNaNLiteral;
    /// What to output when the input is negative NaN.
    string NegNaNLiteral = WriteFloatSettings.Default.NegNaNLiteral;
    /// What to output when the input is positive infinity.
    string PosInfLiteral = WriteFloatSettings.Default.PosInfLiteral;
    /// What to output when the input is negative infinity.
    string NegInfLiteral = WriteFloatSettings.Default.NegInfLiteral;
    /// Whether to output upper- or lower-case hexadecimal digits.
    bool uppercase = false;
}



/// Generate a string given a floating point value in hexadecimal format.
/// http://stackoverflow.com/questions/4825824/hexadecimal-floating-constant-in-c
/// http://c0x.coding-guidelines.com/6.4.4.2.html
string writehexfloat(
    WriteHexFloatSettings settings = WriteHexFloatSettings.Default, T
)(in T value) if(isFloatingPoint!T){
    static if(settings.uppercase){
        enum PosZero = "0X0P0";
        enum NegZero = "-" ~ PosZero;
        enum NormalWhole = "0X1";
        enum SubnormalWhole = "0X0";
        enum ExpPrefix = "P";
        enum Digits = "0123456789ABCDEF";
    }else{
        enum PosZero = "0x0p0";
        enum NegZero = "-" ~ PosZero;
        enum NormalWhole = "0x1";
        enum SubnormalWhole = "0x0";
        enum ExpPrefix = "p";
        enum Digits = "0123456789abcdef";
    }
    if(value.fisnan){
        return value.fextractsgn ? settings.NegNaNLiteral : settings.PosNaNLiteral;
    }else if(value.fisinf){
        return value > 0 ? settings.PosInfLiteral : settings.NegInfLiteral;
    }else if(value.fiszero){
        return value.fextractsgn ? NegZero : PosZero;
    }else{
        enum Format = IEEEFormatOf!T;
        immutable whole = value.fisnormal ? NormalWhole : SubnormalWhole;
        immutable exp = ExpPrefix ~ value.fextractsexp.writeint;
        
        static if(Format.intpart){
            immutable sig = value.fextractsig & pow2d!(Format.sigsize - 1);
        }else{
            immutable sig = value.fextractsig;
        }
        
        if(sig != 0){
            string fraction;
            int pos = Format.sigsize - Format.intpart - 4;
            typeof(fraction.length) lastnonzero = 0;
            while(pos >= 0){
                immutable digit = (sig >> pos) & 0xf;
                fraction ~= Digits[digit];
                if(digit != 0) lastnonzero = fraction.length;
                pos -= 4;
            }
            static if((Format.sigsize - Format.intpart) % 4 != 0){{
                // Get last digit when number of binary digits wasn't a multiple of 4
                immutable digit = (sig << -pos) & 0xf;
                fraction ~= Digits[digit];
                if(digit != 0) lastnonzero = fraction.length;
            }}
            immutable unsigned = whole ~ "." ~ fraction[0 .. lastnonzero] ~ exp;
            return value > 0 ? unsigned : "-" ~ unsigned;
        }else{
            immutable unsigned = whole ~ exp;
            return value > 0 ? unsigned : "-" ~ unsigned;
        }
    }
}



/// Possible internal states for `parsehexfloat`.
private static enum ParseHexFloatState{
    Initial, /// Expecting '0x', '+0x', or '-0x'.
    InitialSigned, /// Found '+' or '-', expecting '0x'.
    InitialX, /// Expecting 'x' or 'X' as part of '0x' prefix.
    IntegralInitial, /// Expecting either '.' or a hexadecimal digit.
    Integral, /// Expecting hexadecimal digits and then either '.' or 'p'/'P'.
    Fraction, /// Expecting hexadecimal digits and then 'p'/'P'.
    ExponentInitial, /// Expecting either '+' or '-' or decimal digits.
    ExponentSigned, /// Expecting decimal digits.
    Exponent, /// Expecting decimal digits and then EOF.
}

/// Parse a floating point value given a string in hexadecimal format.
/// Throws a `NumberParseException` when the input was malformed.
T parsehexfloat(T = double, S)(auto ref S str) if(isFloatingPoint!T && isString!S){
    static const error = new NumberParseException();
    
    alias Mantissa = ulong;
    alias Exponent = uint;
    alias State = ParseHexFloatState;
    State state = State.Initial;
    
    // The most significant digits of the mantissa.
    Mantissa mantissa = 0;
    // Number of binary digits (not hex) in the mantissa;
    // can be less than the number in the string.
    uint mantdigits = 0;
    // Number of binary (not hex) digits preceding the decimal point.
    uint decimal = 0;
    // Whether the mantissa is negative.
    bool mantnegative = false;
    // Whether the mantissa has overflowed.
    bool mantoverflow = false;
    
    /// Base 2 exponent.
    Exponent exponent = 0;
    // Whether the exponent is negative.
    bool expnegative = false;
    // Whether the exponent has overflowed.
    bool expoverflow = false;
    
    void addmantdigit(in uint digit){
        if(!mantoverflow){
            immutable result = intfmaoverflow(mantissa, 16, digit);
            if(result.overflow){
                mantoverflow = true;
                // Handle a partial final digit, necessary for reals.
                int i = 4;
                while(i > 0 && !(mantissa & pow2!(Mantissa.sizeof * 8 - 1))){
                    i--;
                    mantdigits++;
                    mantissa = (mantissa << 1) | ((digit >> i) & 1);
                }
            }else{
                mantissa = result.value;
                mantdigits += 4;
            }
        }
    }
    auto addexpdigit(in uint digit){
        if(!expoverflow){
            immutable result = intfmaoverflow(exponent, 10, digit);
            if(result.overflow){
                expoverflow = true;
            }else{
                exponent = result.value;
            }
        }
    }
    
    void consumedigit(in uint digit){
        switch(state){
            case State.IntegralInitial:
                state = State.Integral;
                goto case;
            case State.Integral:
                decimal += 4;
                goto case;
            case State.Fraction:
                addmantdigit(digit);
                break;
            case State.ExponentInitial:
                goto case;
            case State.ExponentSigned:
                state = State.Exponent;
                goto case;
            case State.Exponent:
                if(digit >= 10) throw error;
                addexpdigit(digit);
                break;
            default:
                assert(false); // Shouldn't happen
        }
    }
    
    foreach(ch; str){
        if(state is State.Initial){
            if(ch == '0'){
                state = State.InitialX;
            }else if(ch == '+' || ch == '-'){
                state = State.InitialSigned;
                mantnegative = (ch == '-');
            }else{
                throw error;
            }
        }else if(state is State.InitialSigned){
            if(ch != '0') throw error;
            state = State.InitialX;
        }else if(state is State.InitialX){
            if(ch != 'x' && ch != 'X') throw error;
            state = State.IntegralInitial;
        }else if(ch >= '0' && ch <= '9'){
            consumedigit(ch - '0');
        }else if(ch >= 'a' && ch <= 'f'){
            consumedigit(ch - 'a' + 10);
        }else if(ch >= 'A' && ch <= 'F'){
            consumedigit(ch - 'A' + 10);
        }else if(ch == '.'){
            if(state !is State.IntegralInitial && state !is State.Integral) throw error;
            state = State.Fraction;
        }else if(ch == 'p' || ch == 'P'){
            if(state !is State.Integral && state !is State.Fraction) throw error;
            state = State.ExponentInitial;
        }else if(ch == '+' || ch == '-'){
            if(state !is State.ExponentInitial) throw error;
            state = State.ExponentSigned;
            expnegative = (ch == '-');
        }else{
            throw error;
        }
    }
    
    // Finished consuming the string; build a float from the information.
    if(state is State.Integral){
        immutable value = cast(T) mantissa;
        return mantnegative ? -value : value;
    }else if(state is State.Fraction){
        immutable exp = cast(int) decimal - cast(int) mantdigits;
        immutable value = cast(T) mantissa * fcomposeexp!T(exp);
        return mantnegative ? -value : value;
    }else if(state is State.Exponent){
        immutable exp0 = expnegative ? -(cast(int) exponent) : cast(int) exponent;
        immutable exp1 = (cast(int) decimal - cast(int) mantdigits);
        immutable value = cast(T) mantissa * fcomposeexp!T(exp0 + exp1);
        return mantnegative ? -value : value;
    }else{
        throw error; // Unexpected EOF
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats : fidentical;
    import mach.error.mustthrow : mustthrow;
}

unittest{ /// Write and parse normal floats
    foreach(T; Aliases!(float, double, real)){
        foreach(valuestr; Aliases!(
            "0x0p0", "0x1p0", "0x1p1", "0x1p-1", "0x1p10", "0x1p-10",
            "0x1.234p0", "0x1.5678p1", "0x1.5678p-1", "0x1.55555p-120",
            "0x1.fffffep0" // Greatest representable float significand
        )){
            mixin(`T value = ` ~ valuestr ~ `;`);
            assert(writehexfloat(value) == valuestr);
            assert(writehexfloat(-value) == `-` ~ valuestr);
            assert(fidentical(parsehexfloat!T(valuestr), value));
            assert(fidentical(parsehexfloat!T(`+` ~ valuestr), value));
            assert(fidentical(parsehexfloat!T(`-` ~ valuestr), -value));
        }
    }
}
unittest{ /// Write and parse normal doubles
    foreach(T; Aliases!(double, real)){
        foreach(valuestr; Aliases!(
            "0x1p300", "0x1p-300", "0x1.23456p256", "0x1.44444p-4",
            "0x1.fffffffffffffp0" // Greatest representable double significand
        )){
            mixin(`T value = ` ~ valuestr ~ `;`);
            assert(writehexfloat(value) == valuestr);
            assert(writehexfloat(-value) == `-` ~ valuestr);
            assert(fidentical(parsehexfloat!T(valuestr), value));
            assert(fidentical(parsehexfloat!T(`+` ~ valuestr), value));
            assert(fidentical(parsehexfloat!T(`-` ~ valuestr), -value));
        }
    }
}
unittest{ /// Write and parse normal reals
    alias T = real;
    foreach(valuestr; Aliases!(
        "0x1p16000", "0x1p-16000", "0x1.23456p2560",
        "0x1.fffffffffffffffep0" // Greatest representable real significand
    )){
        mixin(`T value = ` ~ valuestr ~ `L;`);
        assert(writehexfloat(value) == valuestr);
        assert(writehexfloat(-value) == `-` ~ valuestr);
        assert(fidentical(parsehexfloat!T(valuestr), value));
        assert(fidentical(parsehexfloat!T(`+` ~ valuestr), value));
        assert(fidentical(parsehexfloat!T(`-` ~ valuestr), -value));
    }
}

unittest{ /// Write subnormals
    assert(writehexfloat(float(0x0.0123p-126)) == "0x0.0123p-126");
    assert(writehexfloat(double(0x0.0123p-1022L)) == "0x0.0123p-1022");
    assert(writehexfloat(real(0x0.0123p-16382L)) == "0x0.0123p-16382");
}

unittest{ /// Parse subnormals
    assert(fidentical(parsehexfloat!float("0x0.0123p-126"), float(0x0.0123p-126)));
    assert(fidentical(parsehexfloat!double("0x0.0123p-1022"), double(0x0.0123p-1022L)));
    assert(fidentical(parsehexfloat!real("0x0.0123p-16382"), real(0x0.0123p-16382L)));
}

unittest{ /// Write infinities and NaN
    enum Settings = WriteHexFloatSettings.Default;
    foreach(T; Aliases!(float, double, real)){
        assert(writehexfloat(T.infinity) == Settings.PosInfLiteral);
        assert(writehexfloat(-T.infinity) == Settings.NegInfLiteral);
        assert(writehexfloat(T.nan) == Settings.PosNaNLiteral);
        assert(writehexfloat(-T.nan) == Settings.NegNaNLiteral);
    }
}

unittest{ /// Write upper case
    enum WriteHexFloatSettings Settings = {uppercase: true};
    assert(writehexfloat!Settings(0X1.1234P12) == "0X1.1234P12");
    assert(writehexfloat!Settings(0X1.ABCDP-12) == "0X1.ABCDP-12");
}

unittest{ /// Parse various inputs
    foreach(T; Aliases!(float, double, real)){
        foreach(valuestr; Aliases!(
            "0x12.34P1", "0xabc.DEFp-2", "0Xabp1", "0XABP1", "0X.23p11",
            "0x.p10", "0x.p-10", "0x1.p10", "0x1.p-10", "0x.1p10", "0x.1p-10",
            "0x0", "0x1", "0x12", "0x256", "0x12345", "0xabdef", "0xABDEF"
        )){
            mixin(`T value = ` ~ valuestr ~ `L;`);
            assert(fidentical(parsehexfloat!T(valuestr), value));
            assert(fidentical(parsehexfloat!T(`+` ~ valuestr), value));
            assert(fidentical(parsehexfloat!T(`-` ~ valuestr), -value));
        }
    }
}

unittest{ /// Parse very large/small inputs
    auto posbig = parsehexfloat!float("0x1p128");
    assert(posbig > 0 && posbig.fisinf);
    auto negbig = parsehexfloat!float("-0x1p128");
    assert(negbig < 0 && negbig.fisinf);
    auto small = parsehexfloat!float("0x1p-150");
    assert(small == 0);
}

unittest{ /// Malformed parse inputs
    void bad(string str){
        mustthrow!NumberParseException({
            parsehexfloat!float(str);
        });
        mustthrow!NumberParseException({
            parsehexfloat!double(str);
        });
        mustthrow!NumberParseException({
            parsehexfloat!real(str);
        });
    }
    bad("");
    bad(".");
    bad("x");
    bad("e");
    bad("p");
    bad("P");
    bad("+");
    bad("-");
    bad("xx");
    bad("0");
    bad("0x");
    bad("-0x");
    bad("+0x");
    bad("0xx");
    bad("0x0x");
    bad("0x0abc.dexpx");
    bad("0x0p");
    bad("0x0p+");
    bad("0x0p-");
    bad("0x0px");
    bad("0x0p0x");
}
