module mach.range.asrange.as;

private:

import mach.traits : isRange, isSavingRange, isRandomAccessRange;
import mach.traits : isBidirectionalRange, isSlicingRange, canReassign;
import mach.traits : isMutableFrontRange, isMutableBackRange, isMutableRandomRange;
import mach.traits : isArray, isAssociativeArray;
import mach.range.asrange.aarange;
import mach.range.asrange.arrayrange;
import mach.range.asrange.indexrange;

public:



/// Determine if a range can be created from a type, or if it already is a range.
template validAsRange(T){
    static if(is(typeof({auto x = T.init.asrange;}))){
        enum bool validAsRange = isRange!(typeof({return T.init.asrange;}()));
    }else{
        enum bool validAsRange = false;
    }
}

template validAsRange(T...) if(T.length > 1){
    alias Type = T[$-1];
    alias predicates = T[0 .. $-1];
    static if(predicates.length == 1){
        static if(validAsRange!Type){
            alias Predicate = predicates[0];
            enum bool validAsRange = Predicate!(AsRangeType!Type);
        }else{
            enum bool validAsRange = false;
        }
    }else{
        enum bool validAsRange = (
            validAsRange!(predicates[0], Type) &&
            validAsRange!(predicates[1 .. $], Type)
        );
    }
}



enum validAsBidirectionalRange(T) = validAsRange!(isBidirectionalRange, T);
enum validAsRandomAccessRange(T) = validAsRange!(isRandomAccessRange, T);
enum validAsSlicingRange(T) = validAsRange!(isSlicingRange, T);
enum validAsSavingRange(T) = validAsRange!(isSavingRange, T);
enum validAsMutableFrontRange(T) = validAsRange!(isMutableFrontRange, T);
enum validAsMutableBackRange(T) = validAsRange!(isMutableBackRange, T);
enum validAsMutableRandomRange(T) = validAsRange!(isMutableRandomRange, T);



template AsRangeType(T) if(validAsRange!T){
    alias AsRangeType = typeof({return T.init.asrange;}());
}

template AsRangeElementType(T) if(validAsRange!T){
    static if(isRange!T){
        alias AsRangeElementType = typeof({return T.init.front;}());
    }else{
        alias AsRangeElementType = typeof({return T.init.asrange.front;}());
    }
}



/// Get a range for iterating over some object.
auto asrange(T)(auto ref T range) if(isRange!T){
    return range;
}

/// ditto
auto asrange(T)(auto ref T array) if(isArray!T){
    return ArrayRange!T(array);
}

/// ditto
auto asrange(T)(auto ref T array) if(isAssociativeArray!T){
    return AssociativeArrayRange!T(array);
}



// TODO: More tests
version(unittest){
    private:
    import mach.types : KeyValuePair;
    struct InfRange{
        enum bool empty = false;
        @property int front(){return 0;}
        void popFront(){}
    }
}
unittest{
    static assert(is(AsRangeType!InfRange == InfRange));
    static assert(is(AsRangeType!(int[]) == ArrayRange!(int[])));
    static assert(is(AsRangeType!(int[int]) == AssociativeArrayRange!(int[int])));
}
unittest{
    static assert(is(AsRangeElementType!InfRange == int));
    static assert(is(AsRangeElementType!(int[]) == int));
    static assert(is(AsRangeElementType!(int[int]) == KeyValuePair!(int, int)));
}
