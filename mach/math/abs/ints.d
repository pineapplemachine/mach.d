module mach.math.abs.ints;

private:

import mach.traits.primitives : Unsigned, isSignedIntegral, isUnsignedIntegral;

public:



/// Get the absolute value of a given number.
T abs(T)(in T value) if(isUnsignedIntegral!T){
    return value;
}
/// ditto
T abs(T)(in T value) if(isSignedIntegral!T){
    return value >= 0 ? value : cast(T) -value;
}



/// Get the absolute value of a signed or unsigned integer,
/// and get an unsigned integer back.
/// This functionality is significant because the absolute value of,
/// for example, `int.min` is not actually storeable in an int.
T uabs(T)(in T value) if(isUnsignedIntegral!T){
    return value;
}
/// ditto
Unsigned!T uabs(T)(in T value) if(isSignedIntegral!T){
    if(value >= 0) return cast(Unsigned!T) value;
    else if(value == T.min) return (cast(Unsigned!T) T.max) + 1;
    else return cast(Unsigned!T) -value;
}



private version(unittest){
    import mach.meta.aliases : Aliases;
}
unittest{
    foreach(T; Aliases!(ubyte, ushort, uint, ulong)){
        assert(abs(T(0)) == 0);
        assert(abs(T(1)) == 1);
    }
    foreach(T; Aliases!(byte, short, int, long)){
        assert(abs(T(0)) == 0);
        assert(abs(T(1)) == 1);
        assert(abs(T(-1)) == 1);
    }
}
unittest{
    foreach(T; Aliases!(ubyte, ushort, uint, ulong)){
        assert(uabs(T(0)) == 0);
        assert(uabs(T(1)) == 1);
    }
    foreach(T; Aliases!(byte, short, int, long)){
        assert(uabs(T(0)) == 0);
        assert(uabs(T(1)) == 1);
        assert(uabs(T(-1)) == 1);
        assert(uabs(T.min) == (cast(Unsigned!T) T.max) + 1);
    }
}
