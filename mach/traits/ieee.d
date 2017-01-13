module mach.traits.ieee;

private:

import mach.traits.primitives : isFloatingPoint;

public:



/// Contains information describing an IEEE format.
struct IEEEFormat{
    pure @safe @nogc nothrow:
    
    /// Offset in bits of the sign bit.
    uint sgnoffset;
    /// Offset in bits of the exponent.
    uint expoffset;
    /// Size in bits of the exponent.
    uint expsize;
    /// Exponent bias; this number is subtracted from the exponent to determine
    /// the actual power of two.
    uint expbias;
    /// Offset in bits of the significand.
    static enum uint sigoffset = 0;
    /// Size in bits of the significand.
    uint sigsize;
    /// Whether the first bit of the significand represents an integer part,
    /// such as for the x86 extended precision format.
    bool intpart = false;
    
    /// The maximum storable value by the format's exponent bits.
    @property uint expmax() const{
        return (1 << this.expsize) - 1;
    }
    
    /// The minimum normal or subnormal exponent.
    @property sexpmin() const{
        return -(cast(int) this.expbias);
    }
    /// The maximum normal exponent.
    @property sexpmax() const{
        return this.expmax - this.expbias - 1;
    }
    
    /// Subnormal numbers are represented by `2 ^ -x`
    /// where `x` is the value of this property.
    @property uint expsubnormal() const{
        return 1 - this.expbias;
    }
    
    /// When `intpart` is true, returns the bit offset of the
    /// format's integral part.
    @property uint intpartoffset() const{
        return this.sigoffset + this.sigsize - 1;
    }
    
    /// https://en.wikipedia.org/wiki/Half-precision_floating-point_format
    static immutable IEEEFormat Half = {
        sgnoffset: 15,
        expoffset: 10,
        expsize: 5,
        expbias: 0xf,
        sigsize: 10,
        intpart: false,
    };
    /// https://en.wikipedia.org/wiki/Single-precision_floating-point_format
    static immutable IEEEFormat Single = {
        sgnoffset: 31,
        expoffset: 23,
        expsize: 8,
        expbias: 0x7f,
        sigsize: 23,
        intpart: false,
    };
    /// https://en.wikipedia.org/wiki/Double-precision_floating-point_format
    static immutable IEEEFormat Double = {
        sgnoffset: 63,
        expoffset: 52,
        expsize: 11,
        expbias: 0x3ff,
        sigsize: 52,
        intpart: false,
    };
    /// https://en.wikipedia.org/wiki/Extended_precision#x86_Extended_Precision_Format
    static immutable IEEEFormat Extended = {
        sgnoffset: 79,
        expoffset: 64,
        expsize: 15,
        expbias: 0x3fff,
        sigsize: 64,
        intpart: true,
    };
    /// https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_formatint_format
    static immutable IEEEFormat Quad = {
        sgnoffset: 127,
        expoffset: 112,
        expsize: 15,
        expbias: 0x3fff,
        sigsize: 112,
        intpart: false,
    };
}



/// Get the IEEEFormat corresponding to a floating point type.
/// Causes an assert error if the format is unrecognized.
template IEEEFormatOf(T) if(isFloatingPoint!T){
    static if(T.mant_dig == 24){
        alias IEEEFormatOf = IEEEFormat.Single;
    }else static if(T.mant_dig == 53){
        static if (T.sizeof == 8){
            alias IEEEFormatOf = IEEEFormat.Double;
        }else static if(T.sizeof == 12){
            // Should be x86 extended, rounded to double
            // Though I am not confident in that assessment
            // TODO: Find some way to test this assumption
            alias IEEEFormatOf = IEEEFormat.Extended;
        }else{
            static assert(false);
        }
    }else static if(T.mant_dig == 64){
        alias IEEEFormatOf = IEEEFormat.Extended;
    }else static if(T.mant_dig == 113){
        alias IEEEFormatOf = IEEEFormat.Quad;
    }else{
        static assert(false, "Unrecognized floating point format.");
    }
}



unittest{
    static assert(IEEEFormatOf!float is IEEEFormat.Single);
    static assert(IEEEFormatOf!double is IEEEFormat.Double);
    version(X86) static assert(IEEEFormatOf!real is IEEEFormat.Extended);
}
