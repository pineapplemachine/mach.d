module mach.traits.qualifiers;

private:

/++ Docs

This module implements the `Unqual`, `isUnqual`, and `Qualify` templates for
manipulating the qualifiers `immutable`, `shared`, `inout`, and `const` that
may be associated with types.

The `Unqual` template aliases an inputted type with all of its qualifiers
stripped.

+/

unittest{ /// Example
    static assert(is(Unqual!(const int) == int));
    static assert(is(Unqual!(shared inout int) == int));
    static assert(is(Unqual!(int) == int));
}

/++ Docs

The `isUnqual` template compares two or more types for equality, regardless
of differing qualifiers.

+/

unittest{ /// Example
    static assert(isUnqual!(const int, immutable int));
    static assert(isUnqual!(string, shared string));
    static assert(!isUnqual!(float, double));
}

/++ Docs

The `Qualify` template takes two types and outputs the second type with
the same qualifiers as the first type.

+/

unittest{ /// Example
    static assert(is(Qualify!(const int, string) == const string));
    static assert(is(Qualify!(shared inout int, string) == shared inout string));
    static assert(is(Qualify!(shared int, immutable string) == shared string));
    static assert(is(Qualify!(int, shared const string) == string));
}

public:



/// Strip all qualifiers from a type, if any.
template Unqual(T){
    static if(is(T R == immutable R)) alias Unqual = R;
    else static if(is(T R == shared inout const R)) alias Unqual = R;
    else static if(is(T R == shared inout R)) alias Unqual = R;
    else static if(is(T R == shared const R)) alias Unqual = R;
    else static if(is(T R == inout const R)) alias Unqual = R;
    else static if(is(T R == shared R)) alias Unqual = R;
    else static if(is(T R == inout R)) alias Unqual = R;
    else static if(is(T R == const R)) alias Unqual = R;
    else alias Unqual = T;
}



/// Determine if all given types are identical, disregarding qualifiers.
template isUnqual(T...){
    static if(T.length <= 1){
        enum bool isUnqual = true;
    }else static if(T.length == 2){
        enum bool isUnqual = is(Unqual!(T[0]) == Unqual!(T[1]));
    }else{
        enum bool isUnqual = (
            is(Unqual!(T[0]) == Unqual!(T[1])) &&
            isUnqual!(T[2 .. $])
        );
    }
}



/// Get the second type with all the same qualifiers as the first type.
template Qualify(Q, T){
    alias U = Unqual!T;
    static if(is(Q R == immutable R)) alias Qualify = immutable U;
    else static if(is(Q R == shared inout const R)) alias Qualify = shared inout const U;
    else static if(is(Q R == shared inout R)) alias Qualify = shared inout U;
    else static if(is(Q R == shared const R)) alias Qualify = shared const U;
    else static if(is(Q R == inout const R)) alias Qualify = inout const U;
    else static if(is(Q R == shared R)) alias Qualify = shared U;
    else static if(is(Q R == inout R)) alias Qualify = inout U;
    else static if(is(Q R == const R)) alias Qualify = const U;
    else alias Qualify = U;
}



private version(unittest){
    import mach.meta.aliases : Aliases;
    class TestClass{}
    struct TestStruct{}
    struct TestTmplStruct(T){}
    enum TestEnum{A, B, C}
    enum TestEnumI: int{A, B, C}
    alias TestTypes = Aliases!(
        int, long, double, char, string,
        TestClass, TestStruct, TestTmplStruct!int,
        TestEnum, TestEnumI
    );
}

unittest{
    foreach(T; TestTypes){
        static assert(is(Unqual!(T) == T));
        static assert(is(Unqual!(immutable T) == T));
        static assert(is(Unqual!(shared inout const T) == T));
        static assert(is(Unqual!(shared inout T) == T));
        static assert(is(Unqual!(shared const T) == T));
        static assert(is(Unqual!(shared T) == T));
        static assert(is(Unqual!(inout const T) == T));
        static assert(is(Unqual!(inout T) == T));
        static assert(is(Unqual!(const T) == T));
    }
}

unittest{
    foreach(T; TestTypes){
        static assert(isUnqual!());
        static assert(isUnqual!(T));
        static assert(isUnqual!(T, T));
        static assert(isUnqual!(T, immutable T));
        static assert(isUnqual!(T, shared inout const T));
        static assert(isUnqual!(T, shared inout T));
        static assert(isUnqual!(T, shared const T));
        static assert(isUnqual!(T, shared T));
        static assert(isUnqual!(T, inout const T));
        static assert(isUnqual!(T, inout T));
        static assert(isUnqual!(T, const T));
        static assert(isUnqual!(immutable T, T));
        static assert(isUnqual!(shared inout const T, T));
        static assert(isUnqual!(shared inout T, T));
        static assert(isUnqual!(shared const T, T));
        static assert(isUnqual!(shared T, T));
        static assert(isUnqual!(inout const T, T));
        static assert(isUnqual!(inout T, T));
        static assert(isUnqual!(const T, T));
        static assert(isUnqual!(const T, immutable T));
        static assert(isUnqual!(const T, shared T));
        static assert(isUnqual!(const inout T, shared inout T));
        static assert(isUnqual!(T, T, T));
        static assert(isUnqual!(T, const T, immutable T));
        static assert(isUnqual!(shared T, shared const T, inout const T, const T));
    }
}
unittest{
    static assert(!isUnqual!(int, void));
    static assert(!isUnqual!(int, double));
    static assert(!isUnqual!(const int, double));
    static assert(!isUnqual!(const int, const double));
    static assert(!isUnqual!(int, double, float));
}

unittest{
    static assert(is(Qualify!(void, int) == int));
    static assert(is(Qualify!(void, const int) == int));
    static assert(is(Qualify!(void, immutable int) == int));
    static assert(is(Qualify!(const void, immutable int) == const int));
    static assert(is(Qualify!(immutable void, int) == immutable int));
    static assert(is(Qualify!(immutable void, immutable int) == immutable int));
    static assert(is(Qualify!(shared inout void, const int) == shared inout int));
}
