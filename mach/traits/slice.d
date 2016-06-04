module mach.traits.slice;

private:

//

public:



/// Determine whether a type can be sliced using the given types.
template canSlice(T, Low, High){
    enum bool canSlice = is(typeof((inout int = 0){
        auto slice = T.init[Low.init .. High.init];
    }));
}

enum canSlice(T) = canSlice!(T, size_t);
enum canSlice(T, Low) = canSlice!(T, Low, Low);

template canSlice(alias pred, T, Low, High){
    static if(canSlice!(T, Low, High)){
        enum bool canSlice = pred!(SliceType!(T, Low, High));
    }else{
        enum bool canSlice = false;
    }
}



/// Determine whether slicing a type with the given types yields some object of
/// the same type as what's been sliced.
template canSliceSame(T, Low, High){
    static if(canSlice!(T, Low, High)){
        enum bool canSliceSame = is(T == SliceType!(T, Low, High));
    }else{
        enum bool canSliceSame = false;
    }
}

enum canSliceSame(T) = canSliceSame!(T, size_t);
enum canSliceSame(T, Low) = canSliceSame!(T, Low, Low);

template canSliceSame(alias pred, T, Low, High){
    static if(canSliceSame!(T, Low, High)){
        enum bool canSlice = pred!(SliceType!(T, Low, High));
    }else{
        enum bool canSlice = false;
    }
}



template SliceType(T){
    alias SliceType = SliceType!(T, size_t);
}

template SliceType(T, Low){
    alias SliceType = SliceType!(T, Low, Low);
}

template SliceType(T, Low, High) if(canSlice!(T, Low, High)){
    alias SliceType = typeof(T.init[Low.init .. High.init]);
}



unittest{
    // canSlice
    static assert(canSlice!(int[], size_t));
    static assert(canSlice!(string, size_t));
    static assert(canSlice!(string, int));
    static assert(canSlice!(string, int, short));
    static assert(!canSlice!(int, size_t));
    static assert(!canSlice!(int[], string));
    static assert(!canSlice!(string, string));
    static assert(!canSlice!(string, string, size_t));
    // canSliceSame
    static assert(canSliceSame!(int[]));
    static assert(canSliceSame!(string));
    static assert(canSliceSame!(int[][]));
}
