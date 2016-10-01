module mach.traits.qualifiers;

private:

//

public:



/// Strip all qualifiers from a type, if any.
template Unqual(alias T){
    alias Unqual = Unqual!(typeof(T));
}
/// ditto
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



version(unittest){
    private:
    import mach.meta : Aliases;
    class TestClass{}
    struct TestStruct{}
    struct TestTmplStruct(T){}
    alias TestTypes = Aliases!(
        int, long, double, char, string,
        TestClass, TestStruct, TestTmplStruct!int
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
    {
        static assert(!isUnqual!(int, void));
        static assert(!isUnqual!(int, double));
        static assert(!isUnqual!(const int, double));
        static assert(!isUnqual!(const int, const double));
        static assert(!isUnqual!(int, double, float));
    }
}
