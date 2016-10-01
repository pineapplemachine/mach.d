module mach.traits.size;

private:

//

public:



/// Get the highest sizeof of the given types.
template LargestSizeOf(T...) if(T.length){
    enum LargestSizeOf = LargestSizeOfType!T.sizeof;
}

/// Get the type with the largest sizeof value.
template LargestSizeOfType(T...) if(T.length){
    static if(T.length == 1){
        alias LargestSizeOfType = T[0];
    }else static if(T.length == 2){
        static if(T[0].sizeof >= T[1].sizeof) alias LargestSizeOfType = T[0];
        else alias LargestSizeOfType = T[1];
    }else{
        alias LargestSizeOfType = LargestSizeOfType!(
            LargestSizeOfType!(T[0 .. 2]),
            LargestSizeOfType!(T[2 .. $])
        );
    }
}



/// Get the smallest sizeof of the given types.
template SmallestSizeOf(T...) if(T.length){
    enum SmallestSizeOf = SmallestSizeOfType!T.sizeof;
}

/// Get the type with the smallest sizeof value.
template SmallestSizeOfType(T...) if(T.length){
    static if(T.length == 1){
        alias SmallestSizeOfType = T[0];
    }else static if(T.length == 2){
        static if(T[0].sizeof <= T[1].sizeof) alias SmallestSizeOfType = T[0];
        else alias SmallestSizeOfType = T[1];
    }else{
        alias SmallestSizeOfType = SmallestSizeOfType!(
            SmallestSizeOfType!(T[0 .. 2]),
            SmallestSizeOfType!(T[2 .. $])
        );
    }
}



unittest{
    static assert(is(LargestSizeOfType!(int) == int));
    static assert(is(LargestSizeOfType!(int, int) == int));
    static assert(is(LargestSizeOfType!(int, int, int) == int));
    static assert(is(LargestSizeOfType!(byte, short, int) == int));
    static assert(is(LargestSizeOfType!(int, long, int) == long));
    static assert(LargestSizeOf!(int) == 4);
    static assert(LargestSizeOf!(int, int) == 4);
    static assert(LargestSizeOf!(int, int, int) == 4);
    static assert(LargestSizeOf!(int, uint) == 4);
    static assert(LargestSizeOf!(int, long) == 8);
    static assert(LargestSizeOf!(int, byte) == 4);
}
unittest{
    static assert(is(SmallestSizeOfType!(int) == int));
    static assert(is(SmallestSizeOfType!(int, int) == int));
    static assert(is(SmallestSizeOfType!(int, int, int) == int));
    static assert(is(SmallestSizeOfType!(byte, short, int) == byte));
    static assert(is(SmallestSizeOfType!(int, byte, int) == byte));
    static assert(SmallestSizeOf!(int) == 4);
    static assert(SmallestSizeOf!(int, int) == 4);
    static assert(SmallestSizeOf!(int, int, int) == 4);
    static assert(SmallestSizeOf!(int, uint) == 4);
    static assert(SmallestSizeOf!(int, long) == 4);
    static assert(SmallestSizeOf!(int, byte) == 1);
}
