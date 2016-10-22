module mach.traits.ieee;

private:

import mach.traits.primitives : isFloatingPoint;

public:



/// An enumeration of recognized IEEE formats.
enum IEEEFormat: IEEEFormatType{
    /// https://en.wikipedia.org/wiki/Half-precision_floating-point_format
    Half = IEEEFormatType(0),
    /// https://en.wikipedia.org/wiki/Single-precision_floating-point_format
    Single = IEEEFormatType(0),
    /// https://en.wikipedia.org/wiki/Double-precision_floating-point_format
    Double = IEEEFormatType(0),
    /// https://en.wikipedia.org/wiki/Extended_precision#x86_Extended_Precision_Format
    Extended = IEEEFormatType(0),
    Extended53 = IEEEFormatType(0),
    /// https://en.wikipedia.org/wiki/Extended_precision#IBM_extended_precision_formats
    IBMExtended = IEEEFormatType(0),
    /// https://en.wikipedia.org/wiki/Quadruple-precision_floating-point_format
    Quad = IEEEFormatType(0),
}



/// Contains information describing an IEEE format.
struct IEEEFormatType{
    /// Offset of the sign bit.
    uint sgnoffset;
    /// Offset of the exponent.
    uint expoffset;
    /// Size in bits of the exponent.
    uint expsize;
    /// Number to subtract from the exponent to get an accurate value.
    int expbias;
    /// Offset of the significand.
    uint sigoffset;
    /// Size in bits of the significand.
    uint sigize;
    /// Whether the first bit of the significand represents an integer part,
    /// such as for the x86 extended precision format.
    bool intpart;
}



/// Get the IEEEFormatType corresponding to a floating point type.
/// Causes an assert error if the format is unrecognized.
template IEEEFormatOf(T) if(isFloatingPoint!T){
    static if(T.mant_dig == 24){
        alias IEEEFormatOf = IEEEFormat.Single;
    }else static if(T.mant_dig == 53){
        static if (T.sizeof == 8){
            alias IEEEFormatOf = IEEEFormat.Double;
        }else static if(T.sizeof == 12){
            alias IEEEFormatOf = IEEEFormat.Extended53;
        }else{
            static assert(false);
        }
    }else static if(T.mant_dig == 64){
        alias IEEEFormatOf = IEEEFormat.Extended;
    }else static if(T.mant_dig == 106){
        alias IEEEFormatOf = IEEEFormat.IBMExtended;
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
