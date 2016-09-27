module mach.types.types;

private:

import mach.meta.aliases;

public:



/// Used simply to store a sequence of types. Not intended to be instantiated.
struct Types(T...){
    alias Types = T;
    
    // TODO: Would be nice to actually support index and slice operators
    
    /// The number of types represented by this struct.
    static enum length = T.length;
    /// True when the sequence of types is empty.
    static enum bool empty = T.length == 0;
    alias opDollar = length;
    
    /// Get the type at an index.
    alias index = opIndex;
    /// ditto
    static template opIndex(size_t index) if(index >= 0 && index < T.length){
        alias opIndex = T[index];
    }
    /// Get a Types struct containing the types in a slice.
    alias slice = opSlice;
    /// ditto
    static template opSlice(size_t low, size_t high) if(
        low >= 0 && high >= low && high <= length
    ){
        alias opSlice = .Types!(T[low .. high]);
    }
}



unittest{
    alias empty = Types!();
    static assert(empty.length == 0);
    static assert(empty.empty);
    static assert(is(empty.slice!(0, 0) == empty));
    static assert(!is(typeof({empty.index!0;})));
    static assert(!is(typeof({empty.slice!(0, 1);})));
}
unittest{
    alias ints = Types!(int, int, int);
    static assert(ints.length == 3);
    static assert(!ints.empty);
    static assert(is(ints.index!0 == int));
    static assert(is(ints.index!1 == int));
    static assert(is(ints.index!2 == int));
    static assert(is(ints.slice!(0, 0) == Types!()));
    static assert(is(ints.slice!(0, 1) == Types!(int)));
    static assert(is(ints.slice!(0, 3) == ints));
}
unittest{
    alias types = Types!(float, string);
    static assert(types.length == 2);
    static assert(!types.empty);
    static assert(is(types.index!0 == float));
    static assert(is(types.index!1 == string));
}
