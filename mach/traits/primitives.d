module mach.traits.primitives;

private:

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



version(unittest){
    private:
    import mach.meta.aliases : Aliases;
    import mach.meta.logical : All, None;
    struct TestStruct{}
    class TestClass{}
    enum TestEnum{A, B}
    enum TestEnumI: int{A, B}
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
        TestStruct, TestClass, TestEnum, TestEnumI
    );
}
unittest{
    // isBoolean
    static assert(All!(isBoolean, Bools));
    static assert(None!(isBoolean, SInts, UInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isNumeric
    static assert(All!(isNumeric, SInts, UInts, Floats));
    static assert(None!(isNumeric, Bools, Imag, Complex, Chars, Ptrs, Chaff));
    // isIntegral
    static assert(All!(isIntegral, SInts, UInts));
    static assert(None!(isIntegral, Bools, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isFloatingPoint
    static assert(All!(isFloatingPoint, Floats));
    static assert(None!(isFloatingPoint, Bools, SInts, UInts, Imag, Complex, Chars, Ptrs, Chaff));
    // isSignedIntegral
    static assert(All!(isSignedIntegral, SInts));
    static assert(None!(isSignedIntegral, Bools, UInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isUnsignedIntegral
    static assert(All!(isUnsignedIntegral, UInts));
    static assert(None!(isUnsignedIntegral, Bools, SInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isSigned
    static assert(All!(isSigned, SInts, Floats));
    static assert(None!(isSigned, Bools, UInts, Imag, Complex, Chars, Ptrs, Chaff));
    // isUnsigned
    static assert(All!(isUnsigned, UInts));
    static assert(None!(isUnsigned, Bools, SInts, Floats, Imag, Complex, Chars, Ptrs, Chaff));
    // isImaginary
    static assert(All!(isImaginary, Imag));
    static assert(None!(isImaginary, Bools, UInts, SInts, Floats, Complex, Chars, Ptrs, Chaff));
    // isComplex
    static assert(All!(isComplex, Complex));
    static assert(None!(isComplex, Bools, UInts, SInts, Floats, Imag, Chars, Ptrs, Chaff));
    // isCharacter
    static assert(All!(isCharacter, Chars));
    static assert(None!(isCharacter, Bools, UInts, SInts, Floats, Imag, Complex, Ptrs, Chaff));
    // isPointer
    static assert(All!(isPointer, Ptrs));
    static assert(None!(isPointer, Bools, SInts, UInts, Floats, Imag, Complex, Chars, Chaff));
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
