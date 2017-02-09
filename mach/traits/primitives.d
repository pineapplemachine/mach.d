module mach.traits.primitives;

private:

import mach.meta.aliases : Aliases;
import mach.traits.qualifiers : Qualify, Unqual;

public:



private template isCent(T){
    static if(is(cent)) enum bool isSCent = is(T == cent) || is(T == ucent);
    else enum bool isSCent = false;
}

private template isSCent(T){
    static if(is(cent)) enum bool isSCent = is(T == cent);
    else enum bool isSCent = false;
}

private template isUCent(T){
    static if(is(ucent)) enum bool isUCent = is(T == ucent);
    else enum bool isUCent = false;
}



static if(is(cent)){
    /// An alias sequence of all signed integral types.
    alias SignedIntegralTypes = Aliases!(byte, short, int, long, cent);
}else{
    /// ditto
    alias SignedIntegralTypes = Aliases!(byte, short, int, long);
}

static if(is(ucent)){
    /// An alias sequence of all unsigned integral types.
    alias UnsignedIntegralTypes = Aliases!(ubyte, ushort, uint, ulong, ucent);
}else{
    /// ditto
    alias UnsignedIntegralTypes = Aliases!(ubyte, ushort, uint, ulong);
}

/// An alias sequence of all integral types.
alias IntegralTypes = Aliases!(SignedIntegralTypes, UnsignedIntegralTypes);

/// An alias sequence of all floating point types.
alias FloatingPointTypes = Aliases!(float, double, real);

/// An alias sequence of all signed numeric types.
alias SignedTypes = Aliases!(SignedIntegralTypes, FloatingPointTypes);

/// An alias sequence of all unsigned numeric types.
alias UnsignedTypes = UnsignedIntegralTypes;

/// An alias sequence of all numeric types.
alias NumericTypes = Aliases!(IntegralTypes, FloatingPointTypes);

/// An alias sequence of all imaginary number types.
alias ImaginaryTypes = Aliases!(ifloat, idouble, ireal);

/// An alias sequence of all complex number types.
alias ComplexTypes = Aliases!(cfloat, cdouble, creal);

/// An alias sequence of all character types.
alias CharacterTypes = Aliases!(char, wchar, dchar);

/// An alias sequence of all scalar types.
/// Includes booleans, characters, and numbers.
alias ScalarTypes = Aliases!(bool, CharacterTypes, NumericTypes);



/// Get whether a type is null.
template isNull(T){
    enum isNull = is(Unqual!T == typeof(null));
}

/// Get whether a type is a boolean primitive.
template isBoolean(T){
    enum isBoolean = is(Unqual!T == bool);
}

/// Get whether a type is a scalar numeric primitive.
enum isNumeric(T) = (
    isIntegral!T || isFloatingPoint!T
);

/// Get whether a type is a integral numeric primitive.
enum isIntegral(T) = (
    isSignedIntegral!T || isUnsignedIntegral!T
);

/// Get whether a type is a floating point primitive.
template isFloatingPoint(T){
    alias U = Unqual!T;
    enum bool isFloatingPoint = (
        is(U == float) || is(U == double) || is(U == real)
    );
}

/// Get whether a type is a signed integral numeric primitive.
template isSignedIntegral(T){
    alias U = Unqual!T;
    enum bool isSignedIntegral = (
        is(U == byte) || is(U == short) || is(U == int) || is(U == long) || isSCent!U
    );
}

/// Get whether a type is a signed numeric primitive.
enum isSigned(T) = (
    isSignedIntegral!T || isFloatingPoint!T
);

/// Get whether a type is an unsigned numeric primitive.
template isUnsignedIntegral(T){
    alias U = Unqual!T;
    enum bool isUnsignedIntegral = (
        is(U == ubyte) || is(U == ushort) || is(U == uint) || is(U == ulong) || isUCent!U
    );
}

/// Get whether a type is an unsigned numeric primitive.
/// Not currently distinct from isUnsignedIntegral.
alias isUnsigned = isUnsignedIntegral;

/// Get whether a type is an imaginary numeric primitive.
template isImaginary(T){
    alias U = Unqual!T;
    enum bool isImaginary = (
        is(U == ifloat) || is(U == idouble) || is(U == ireal)
    );
}

/// Get whether a type is a complex numeric primitive.
template isComplex(T){
    alias U = Unqual!T;
    enum bool isComplex = (
        is(U == cfloat) || is(U == cdouble) || is(U == creal)
    );
}

/// Get whether a type is a character primitive.
template isCharacter(T){
    alias U = Unqual!T;
    enum bool isCharacter = (
        is(U == char) || is(U == wchar) || is(U == dchar)
    );
}

/// Get whether a type is a scalar primitive. This includes numbers, characters,
/// and booleans.
enum isScalar(T) = (
    isBoolean!T || isNumeric!T || isCharacter!T
);

/// Get whether a type is a pointer.
template isPointer(T){
    enum bool isPointer = is(T == U*, U);
}



/// Get whether a type is a primitive.
/// Includes typeof(null), booleans, integrals, floats, imaginary and complex
/// numbers, and characters.
/// Does not include strings or other arrays, pointers, structs, or classes.
template isPrimitive(T){
    enum bool isPrimitive = (
        isNull!T || isBoolean!T || isNumeric!T ||
        isImaginary!T || isComplex!T || isCharacter!T
    );
}



/// Given a signed or unsigned integral type, get its corresponding unsigned type.
template Unsigned(T) if(isIntegral!T){
    alias U = Unqual!T;
    static if(is(U == byte)) alias Unsigned = Qualify!(T, ubyte);
    else static if(is(U == short)) alias Unsigned = Qualify!(T, ushort);
    else static if(is(U == int)) alias Unsigned = Qualify!(T, uint);
    else static if(is(U == long)) alias Unsigned = Qualify!(T, ulong);
    else static if(isSCent!U) alias Unsigned = Qualify!(T, ucent);
    else alias Unsigned = T;
}

/// Given a signed or unsigned integral type, get its corresponding signed type.
template Signed(T) if(isIntegral!T){
    alias U = Unqual!T;
    static if(is(U == ubyte)) alias Signed = Qualify!(T, byte);
    else static if(is(U == ushort)) alias Signed = Qualify!(T, short);
    else static if(is(U == uint)) alias Signed = Qualify!(T, int);
    else static if(is(U == ulong)) alias Signed = Qualify!(T, long);
    else static if(isUCent!U) alias Signed = Qualify!(T, cent);
    else alias Signed = T;
}



/// Given a floating point, imaginary, or complex type, get its corresponding
/// floating point type.
template FloatingPointType(T) if(isFloatingPoint!T){
    alias FloatingPointType = T;
}
/// Ditto
template FloatingPointType(T) if(isImaginary!T){
    alias FloatingPointType = Qualify!(T, typeof(T.init.im));
}
/// Ditto
template FloatingPointType(T) if(isComplex!T){
    alias FloatingPointType = Qualify!(T, typeof(T.init.re));
}

/// Given a floating point, imaginary, or complex type, get its corresponding
/// imaginary type.
template ImaginaryType(T) if(isFloatingPoint!T){
    alias U = Unqual!T;
    static if(is(U == float)) alias ImaginaryType = Qualify!(T, ifloat);
    else static if(is(U == double)) alias ImaginaryType = Qualify!(T, idouble);
    else static if(is(U == real)) alias ImaginaryType = Qualify!(T, ireal);
    else static assert(false, "Unknown imaginary type.");
}
/// Ditto
template ImaginaryType(T) if(isImaginary!T){
    alias ImaginaryType = T;
}
/// Ditto
template ImaginaryType(T) if(isComplex!T){
    alias ImaginaryType = ImaginaryType!(FloatingPointType!T);
}

/// Given a floating point, imaginary, or complex type, get its corresponding
/// complex type.
template ComplexType(T) if(isFloatingPoint!T){
    alias U = Unqual!T;
    static if(is(U == float)) alias ComplexType = Qualify!(T, cfloat);
    else static if(is(U == double)) alias ComplexType = Qualify!(T, cdouble);
    else static if(is(U == real)) alias ComplexType = Qualify!(T, creal);
    else static assert(false, "Unknown complex type.");
}
/// Ditto
template ComplexType(T) if(isImaginary!T){
    alias ComplexType = ComplexType!(FloatingPointType!T);
}
/// Ditto
template ComplexType(T) if(isComplex!T){
    alias ComplexType = T;
}



version(unittest){
    private:
    import mach.meta.logical : All, None;
    struct TestStruct{}
    class TestClass{}
    enum TestEnum{A, B}
    enum TestEnumI: int{A, B}
    alias Nulls = Aliases!(typeof(null), const typeof(null));
    alias Bools = Aliases!(bool, const bool, const shared inout bool, immutable bool);
    alias SInts = Aliases!(byte, short, int, long, const int);
    alias UInts = Aliases!(ubyte, ushort, uint, ulong, const uint);
    alias Floats = Aliases!(float, double, real, const double);
    alias Imag = Aliases!(ifloat, idouble, ireal, const idouble);
    alias Complex = Aliases!(cfloat, cdouble, creal, const cdouble);
    alias Chars = Aliases!(char, wchar, dchar, const char);
    alias Ptrs = Aliases!(
        void*, int*, long*, string*,
        const(int)*, const(int*),
        immutable(int)*, immutable(int*),
        TestStruct*, TestClass*, TestEnum*
    );
    alias Chaff = Aliases!(
        void, string, int[], int*[], int[][], int[int],
        TestStruct, TestClass, TestEnum, TestEnumI,
        string, wstring, dstring
    );
}
unittest{
    // isNull
    static assert(All!(isNull, Nulls));
    static assert(None!(isNull, Bools, SInts, UInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isBoolean
    static assert(All!(isBoolean, Bools));
    static assert(None!(isBoolean, Nulls, SInts, UInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isNumeric
    static assert(All!(isNumeric, SInts, UInts, Floats));
    static assert(None!(isNumeric, Nulls, Bools, Imag, Complex, Chars, Ptrs, Chaff));
    // isIntegral
    static assert(All!(isIntegral, SInts, UInts));
    static assert(None!(isIntegral, Nulls, Bools, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isFloatingPoint
    static assert(All!(isFloatingPoint, Floats));
    static assert(None!(isFloatingPoint, Nulls, Bools, SInts, UInts, Imag, Complex, Chars, Ptrs, Chaff));
    // isSignedIntegral
    static assert(All!(isSignedIntegral, SInts));
    static assert(None!(isSignedIntegral, Nulls, Bools, UInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isUnsignedIntegral
    static assert(All!(isUnsignedIntegral, UInts));
    static assert(None!(isUnsignedIntegral, Nulls, Bools, SInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isSigned
    static assert(All!(isSigned, SInts, Floats));
    static assert(None!(isSigned, Nulls, Bools, UInts, Imag, Complex, Chars, Ptrs, Chaff));
    // isUnsigned
    static assert(All!(isUnsigned, UInts));
    static assert(None!(isUnsigned, Nulls, Bools, SInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isImaginary
    static assert(All!(isImaginary, Imag));
    static assert(None!(isImaginary, Nulls, Bools, UInts, SInts, Floats, Complex, Chars, Ptrs, Chaff));
    // isComplex
    static assert(All!(isComplex, Complex));
    static assert(None!(isComplex, Nulls, Bools, UInts, SInts, Floats, Imag, Chars, Ptrs, Chaff));
    // isCharacter
    static assert(All!(isCharacter, Chars));
    static assert(None!(isCharacter, Nulls, Bools, UInts, SInts, Floats, Imag, Complex, Ptrs, Chaff));
    // isPointer
    static assert(All!(isPointer, Ptrs));
    static assert(None!(isPointer, Nulls, Bools, SInts, UInts, Floats, Imag, Complex, Chars, Chaff));
    // isPrimitive
    static assert(All!(isPrimitive, Nulls, Bools, UInts, SInts, Floats, Imag, Complex, Chars));
    static assert(None!(isPrimitive, Ptrs, Chaff));
}
unittest{
    static assert(is(Signed!(int) == int));
    static assert(is(Signed!(uint) == int));
    static assert(is(Signed!(const int) == const int));
    static assert(is(Signed!(const uint) == const int));
    static assert(is(Signed!(immutable uint) == immutable int));
    static assert(is(Signed!(const shared uint) == const shared int));
    static assert(is(Signed!(byte) == byte));
    static assert(is(Signed!(ubyte) == byte));
    static assert(is(Signed!(const byte) == const byte));
    static assert(is(Signed!(const ubyte) == const byte));
    static assert(is(Unsigned!(uint) == uint));
    static assert(is(Unsigned!(int) == uint));
    static assert(is(Unsigned!(const uint) == const uint));
    static assert(is(Unsigned!(const int) == const uint));
    static assert(is(Unsigned!(immutable int) == immutable uint));
    static assert(is(Unsigned!(const shared int) == const shared uint));
    static assert(is(Unsigned!(ubyte) == ubyte));
    static assert(is(Unsigned!(byte) == ubyte));
    static assert(is(Unsigned!(const ubyte) == const ubyte));
    static assert(is(Unsigned!(const byte) == const ubyte));
}

unittest{ /// FloatingPointType
    static assert(is(FloatingPointType!(float) == float));
    static assert(is(FloatingPointType!(double) == double));
    static assert(is(FloatingPointType!(real) == real));
    static assert(is(FloatingPointType!(const float) == const float));
    static assert(is(FloatingPointType!(ifloat) == float));
    static assert(is(FloatingPointType!(idouble) == double));
    static assert(is(FloatingPointType!(ireal) == real));
    static assert(is(FloatingPointType!(const ifloat) == const float));
    static assert(is(FloatingPointType!(cfloat) == float));
    static assert(is(FloatingPointType!(cdouble) == double));
    static assert(is(FloatingPointType!(creal) == real));
    static assert(is(FloatingPointType!(const cfloat) == const float));
}
unittest{ /// ImaginaryType
    static assert(is(ImaginaryType!(float) == ifloat));
    static assert(is(ImaginaryType!(double) == idouble));
    static assert(is(ImaginaryType!(real) == ireal));
    static assert(is(ImaginaryType!(const float) == const ifloat));
    static assert(is(ImaginaryType!(ifloat) == ifloat));
    static assert(is(ImaginaryType!(idouble) == idouble));
    static assert(is(ImaginaryType!(ireal) == ireal));
    static assert(is(ImaginaryType!(const ifloat) == const ifloat));
    static assert(is(ImaginaryType!(cfloat) == ifloat));
    static assert(is(ImaginaryType!(cdouble) == idouble));
    static assert(is(ImaginaryType!(creal) == ireal));
    static assert(is(ImaginaryType!(const cfloat) == const ifloat));
}
unittest{ /// ComplexType
    static assert(is(ComplexType!(float) == cfloat));
    static assert(is(ComplexType!(double) == cdouble));
    static assert(is(ComplexType!(real) == creal));
    static assert(is(ComplexType!(const float) == const cfloat));
    static assert(is(ComplexType!(ifloat) == cfloat));
    static assert(is(ComplexType!(idouble) == cdouble));
    static assert(is(ComplexType!(ireal) == creal));
    static assert(is(ComplexType!(const ifloat) == const cfloat));
    static assert(is(ComplexType!(cfloat) == cfloat));
    static assert(is(ComplexType!(cdouble) == cdouble));
    static assert(is(ComplexType!(creal) == creal));
    static assert(is(ComplexType!(const cfloat) == const cfloat));
}
