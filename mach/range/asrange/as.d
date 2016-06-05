module mach.range.asrange.as;

private:

import mach.traits : isRange, isSavingRange, isRandomAccessRange;
import mach.traits : isBidirectionalRange, isSlicingRange, isMutable;
import mach.traits : isMutableFrontRange, isMutableBackRange, isMutableRandomRange;
import mach.range.asrange.aarange;
import mach.range.asrange.arrayrange;
import mach.range.asrange.indexrange;

public:



/// Determine whether a range can be created from a type using makerange.
enum canMakeRange(Base) = (
    canMakeArrayRange!Base ||
    canMakeAssociativeArrayRange!Base ||
    canMakeIndexRange!Base
);

/// Determine if a range can be created from a type, or if it already is a range.
enum validAsRange(T) = (
    isRange!T || canMakeRange!T
);

template validAsRange(alias isType, T){
    static if(isRange!T){
        enum bool validAsRange = isType!T;
    }else static if(validAsRange!T){
        enum bool validAsRange = isType!(AsRangeType!T);
    }else{
        enum bool validAsRange = false;
    }
}

enum validAsBidirectionalRange(T) = validAsRange!(isBidirectionalRange, T);
enum validAsRandomAccessRange(T) = validAsRange!(isRandomAccessRange, T);
enum validAsSlicingRange(T) = validAsRange!(isSlicingRange, T);
enum validAsSavingRange(T) = validAsRange!(isSavingRange, T);
enum validAsMutableFrontRange(T) = validAsRange!(isMutableFrontRange, T);
enum validAsMutableBackRange(T) = validAsRange!(isMutableBackRange, T);
enum validAsMutableRandomRange(T) = validAsRange!(isMutableRandomRange, T);

template MakeRangeType(T) if(canMakeRange!T){
    static if(canMakeArrayRange!T){
        alias MakeRangeType = ArrayRange!T;
    }else static if(canMakeAssociativeArrayRange!T){
        alias MakeRangeType = AssociativeArrayRange!T;
    }else static if(canMakeIndexRange!T){
        alias MakeRangeType = IndexRange!T;
    }else{
        static assert(false); // This shouldn't happen
    }
}

template AsRangeType(T) if(validAsRange!T){
    static if(isRange!T){
        alias AsRangeType = T;
    }else{
        alias AsRangeType = MakeRangeType!T;
    }
}



/// Get a range for iterating over some object.
auto asrange(Base)(Base basis) if(validAsRange!Base){
    static if(isRange!Base){
        return basis;
    }else{
        return makerange(basis);
    }
}

/// Create a range for iterating over some object.
auto makerange(Base)(Base basis) if(canMakeRange!Base){
    return MakeRangeType!Base(basis);
}



unittest{
    // TODO
}
