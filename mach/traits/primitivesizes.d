module mach.traits.primitivesizes;

private:

import mach.traits.qualifiers : Qualify, Unqual;
import mach.traits.primitives : isUnsignedIntegral, isSignedIntegral;
import mach.traits.primitives : isCharacter, isFloatingPoint;
import mach.traits.primitives : isImaginary, isComplex;

/++ Docs

This module implements the `LargerType`, `SmallerType`, `LargestType`, and
`SmallestType` templates.
They can be used to get differently-sized primitives of the same type,
where the type is unsigned or signed integer, character, float, or imaginary or
complex number.

+/

unittest{ /// Example
    static assert(is(LargestType!char == dchar));
    static assert(is(LargestType!float == real));
    static assert(is(SmallestType!wchar == char));
    static assert(is(SmallestType!real == float));
}

unittest{ /// Example
    static assert(is(LargerType!int == long));
    static assert(is(LargerType!char == wchar));
    static assert(is(SmallerType!int == short));
    static assert(is(SmallerType!wchar == char));
}

unittest{ /// Example
    static assert(!is(LargerType!dchar)); // Fails because there is no larger type!
    static assert(!is(SmallerType!ubyte)); // Fails because there is no smaller type!
}

/++ Docs

The `LargestTypeOf` and `SmallestTypeOf` templates accept any number of types as
template arguments, and evaluate to the largest/smallest type provided, as
judged by comparisons of `sizeof`.
When multiple inputs have the same size, the output is that input which appears
earliest in the sequence of inputs.

+/

unittest{ /// Example
    static assert(is(LargestTypeOf!(int, short, byte) == int));
    static assert(is(SmallestTypeOf!(int, short, byte) == byte));
}

public:



/// Get the largest primitive type, e.g. input `int` output `long` or `cent`.
/// Accepts integers, floats, imaginary and complex numbers, and characters.
template LargestType(T) if(isUnsignedIntegral!T){
    static if(is(ucent)) alias LargestType = Qualify!(T, ucent);
    else alias LargestType = Qualify!(T, ulong);
}
/// ditto
template LargestType(T) if(isSignedIntegral!T){
    static if(is(cent)) alias LargestType = Qualify!(T, cent);
    else alias LargestType = Qualify!(T, long);
}
/// ditto
template LargestType(T) if(isCharacter!T){
    alias LargestType = Qualify!(T, dchar);
}
/// ditto
template LargestType(T) if(isFloatingPoint!T){
    alias LargestType = Qualify!(T, real);
}
/// ditto
template LargestType(T) if(isImaginary!T){
    alias LargestType = Qualify!(T, ireal);
}
/// ditto
template LargestType(T) if(isComplex!T){
    alias LargestType = Qualify!(T, creal);
}



/// Get the smallest primitive type, e.g. input `int` output `byte`.
/// Accepts integers, floats, imaginary and complex numbers, and characters.
template SmallestType(T) if(isUnsignedIntegral!T){
    alias SmallestType = Qualify!(T, ubyte);
}
/// ditto
template SmallestType(T) if(isSignedIntegral!T){
    alias SmallestType = Qualify!(T, byte);
}
/// ditto
template SmallestType(T) if(isCharacter!T){
    alias SmallestType = Qualify!(T, char);
}
/// ditto
template SmallestType(T) if(isFloatingPoint!T){
    alias SmallestType = Qualify!(T, float);
}
/// ditto
template SmallestType(T) if(isImaginary!T){
    alias SmallestType = Qualify!(T, ifloat);
}
/// ditto
template SmallestType(T) if(isComplex!T){
    alias SmallestType = Qualify!(T, cfloat);
}



/// Get the next-larger primitive type, e.g. input `int` output `long`.
/// Accepts integers, floats, imaginary and complex numbers, and characters.
/// If there is no larger type, a compile error occurs.
template LargerType(T) if(isUnsignedIntegral!T){
    alias U = Unqual!T;
    static if(is(U == ubyte)){
        alias LargerType = Qualify!(T, ushort);
    }else static if(is(U == ushort)){
        alias LargerType = Qualify!(T, uint);
    }else static if(is(U == uint)){
        alias LargerType = Qualify!(T, ulong);
    }else static if(is(U == ulong)){
        static if(is(ucent)) alias LargerType = Qualify!(T, ucent);
        else static assert(false, "No larger type available.");
    }else{
        static assert(false, "No larger type available.");
    }
}

/// ditto
template LargerType(T) if(isSignedIntegral!T){
    alias U = Unqual!T;
    static if(is(U == byte)){
        alias LargerType = Qualify!(T, short);
    }else static if(is(U == short)){
        alias LargerType = Qualify!(T, int);
    }else static if(is(U == int)){
        alias LargerType = Qualify!(T, long);
    }else static if(is(U == long)){
        static if(is(cent)) alias LargerType = Qualify!(T, cent);
        else static assert(false, "No larger type available.");
    }else{
        static assert(false, "No larger type available.");
    }
}

/// ditto
template LargerType(T) if(isCharacter!T){
    alias U = Unqual!T;
    static if(is(U == char)) alias LargerType = Qualify!(T, wchar);
    else static if(is(U == wchar)) alias LargerType = Qualify!(T, dchar);
    else static assert(false, "No larger type available.");
}

/// ditto
template LargerType(T) if(isFloatingPoint!T){
    alias U = Unqual!T;
    static if(is(U == float)) alias LargerType = Qualify!(T, double);
    else static if(is(U == double)) alias LargerType = Qualify!(T, real);
    else static assert(false, "No larger type available.");
}

/// ditto
template LargerType(T) if(isImaginary!T){
    alias U = Unqual!T;
    static if(is(U == ifloat)) alias LargerType = Qualify!(T, idouble);
    else static if(is(U == idouble)) alias LargerType = Qualify!(T, ireal);
    else static assert(false, "No larger type available.");
}

/// ditto
template LargerType(T) if(isComplex!T){
    alias U = Unqual!T;
    static if(is(U == cfloat)) alias LargerType = Qualify!(T, cdouble);
    else static if(is(U == cdouble)) alias LargerType = Qualify!(T, creal);
    else static assert(false, "No larger type available.");
}



/// Get the next-smaller primitive type, e.g. input `int` output `short`.
/// Accepts integers, floats, imaginary and complex numbers, and characters.
/// If there is no smaller type, a compile error occurs.
template SmallerType(T) if(isUnsignedIntegral!T){
    alias U = Unqual!T;
    static if(is(U == ushort)){
        alias SmallerType = Qualify!(T, ubyte);
    }else static if(is(U == uint)){
        alias SmallerType = Qualify!(T, ushort);
    }else static if(is(U == ulong)){
        alias SmallerType = Qualify!(T, uint);
    }else static if(is(U == ucent)){
        alias SmallerType = Qualify!(T, ulong);
    }else{
        static assert(false, "No smaller type available.");
    }
}

/// ditto
template SmallerType(T) if(isSignedIntegral!T){
    alias U = Unqual!T;
    static if(is(U == short)){
        alias SmallerType = Qualify!(T, byte);
    }else static if(is(U == int)){
        alias SmallerType = Qualify!(T, short);
    }else static if(is(U == long)){
        alias SmallerType = Qualify!(T, int);
    }else static if(is(U == cent)){
        alias SmallerType = Qualify!(T, long);
    }else{
        static assert(false, "No smaller type available.");
    }
}

/// ditto
template SmallerType(T) if(isCharacter!T){
    alias U = Unqual!T;
    static if(is(U == wchar)) alias SmallerType = Qualify!(T, char);
    else static if(is(U == dchar)) alias SmallerType = Qualify!(T, wchar);
    else static assert(false, "No smaller type available.");
}

/// ditto
template SmallerType(T) if(isFloatingPoint!T){
    alias U = Unqual!T;
    static if(is(U == real)) alias SmallerType = Qualify!(T, double);
    else static if(is(U == double)) alias SmallerType = Qualify!(T, float);
    else static assert(false, "No smaller type available.");
}

/// ditto
template SmallerType(T) if(isImaginary!T){
    alias U = Unqual!T;
    static if(is(U == ireal)) alias SmallerType = Qualify!(T, idouble);
    else static if(is(U == idouble)) alias SmallerType = Qualify!(T, ifloat);
    else static assert(false, "No smaller type available.");
}

/// ditto
template SmallerType(T) if(isComplex!T){
    alias U = Unqual!T;
    static if(is(U == creal)) alias SmallerType = Qualify!(T, cdouble);
    else static if(is(U == cdouble)) alias SmallerType = Qualify!(T, cfloat);
    else static assert(false, "No smaller type available.");
}



/// Get the largest input type, as judged by `sizeof`.
/// When multiple inputs are of the same size, the output is that input with
/// the lowest index in the input sequence.
template LargestTypeOf(T...) if(T.length){
    static if(T.length == 1){
        alias LargestTypeOf = T[0];
    }else static if(T.length == 2){
        static if(T[0].sizeof >= T[1].sizeof){
            alias LargestTypeOf = T[0];
        }else{
            alias LargestTypeOf = T[1];
        }
    }else{
        static if(T[0].sizeof >= T[1].sizeof){
            alias LargestTypeOf = LargestTypeOf!(T[0], T[2 .. $]);
        }else{
            alias LargestTypeOf = LargestTypeOf!(T[1], T[2 .. $]);
        }
    }
}

/// Get the smallest input type, as judged by `sizeof`.
/// When multiple inputs are of the same size, the output is that input with
/// the lowest index in the input sequence.
template SmallestTypeOf(T...) if(T.length){
    static if(T.length == 1){
        alias SmallestTypeOf = T[0];
    }else static if(T.length == 2){
        static if(T[0].sizeof <= T[1].sizeof){
            alias SmallestTypeOf = T[0];
        }else{
            alias SmallestTypeOf = T[1];
        }
    }else{
        static if(T[0].sizeof <= T[1].sizeof){
            alias SmallestTypeOf = SmallestTypeOf!(T[0], T[2 .. $]);
        }else{
            alias SmallestTypeOf = SmallestTypeOf!(T[1], T[2 .. $]);
        }
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.traits.primitives : UnsignedIntegralTypes, SignedIntegralTypes;
    import mach.traits.primitives : CharacterTypes, FloatingPointTypes;
    import mach.traits.primitives : ImaginaryTypes, ComplexTypes;
}

unittest{ /// SmallestType and LargestType
    foreach(T; UnsignedIntegralTypes){
        static assert(is(SmallestType!(T) == ubyte));
        static assert(is(SmallestType!(const(T)) == const(ubyte)));
        static if(is(ucent)){
            static assert(is(LargestType!(T) == ucent));
            static assert(is(LargestType!(const(T)) == const(ucent)));
        }else{
            static assert(is(LargestType!(T) == ulong));
            static assert(is(LargestType!(const(T)) == const(ulong)));
        }
    }
    foreach(T; SignedIntegralTypes){
        static assert(is(SmallestType!(T) == byte));
        static assert(is(SmallestType!(const(T)) == const(byte)));
        static if(is(cent)){
            static assert(is(LargestType!(T) == cent));
            static assert(is(LargestType!(const(T)) == const(cent)));
        }else{
            static assert(is(LargestType!(T) == long));
            static assert(is(LargestType!(const(T)) == const(long)));
        }
    }
    foreach(T; CharacterTypes){
        static assert(is(SmallestType!(T) == char));
        static assert(is(SmallestType!(const(T)) == const(char)));
        static assert(is(LargestType!(T) == dchar));
        static assert(is(LargestType!(const(T)) == const(dchar)));
    }
    foreach(T; FloatingPointTypes){
        static assert(is(SmallestType!(T) == float));
        static assert(is(SmallestType!(const(T)) == const(float)));
        static assert(is(LargestType!(T) == real));
        static assert(is(LargestType!(const(T)) == const(real)));
    }
    foreach(T; ImaginaryTypes){
        static assert(is(SmallestType!(T) == ifloat));
        static assert(is(SmallestType!(const(T)) == const(ifloat)));
        static assert(is(LargestType!(T) == ireal));
        static assert(is(LargestType!(const(T)) == const(ireal)));
    }
    foreach(T; ComplexTypes){
        static assert(is(SmallestType!(T) == cfloat));
        static assert(is(SmallestType!(const(T)) == const(cfloat)));
        static assert(is(LargestType!(T) == creal));
        static assert(is(LargestType!(const(T)) == const(creal)));
    }
}

unittest{ /// SmallerType and LargerType
    // Note that this test assumes list in mach.traits.primitives e.g.
    // `UnsignedIntegralTypes` are ordered from smallest to largest.
    foreach(ListName; Aliases!(
        `UnsignedIntegralTypes`, `SignedIntegralTypes`,
        `CharacterTypes`, `FloatingPointTypes`,
        `ImaginaryTypes`, `ComplexTypes`
    )){
        mixin(`alias List = ` ~ ListName ~ `;`);
        foreach(i, T; List){
            static if(i == 0){
                static assert(!is(SmallerType!T));
            }else{
                static assert(is(SmallerType!T == List[i - 1]));
                static assert(is(SmallerType!(const(T)) == const(List[i - 1])));
            }
            static if(i == List.length - 1){
                static assert(!is(LargerType!T));
            }else{
                static assert(is(LargerType!T == List[i + 1]));
                static assert(is(LargerType!(const(T)) == const(List[i + 1])));
            }
        }
    }
}

unittest{ /// SmallestTypeOf and LargestTypeOf
    static assert(is(LargestTypeOf!(int) == int));
    static assert(is(LargestTypeOf!(const int) == const int));
    static assert(is(LargestTypeOf!(int, uint) == int));
    static assert(is(LargestTypeOf!(int, byte, short) == int));
    static assert(is(LargestTypeOf!(byte, short, int) == int));
    static assert(is(SmallestTypeOf!(int) == int));
    static assert(is(SmallestTypeOf!(const int) == const int));
    static assert(is(SmallestTypeOf!(int, uint) == int));
    static assert(is(SmallestTypeOf!(int, long, double) == int));
    static assert(is(SmallestTypeOf!(long, double, int) == int));
}
