module mach.traits.element.range;

private:

import mach.traits.range : isRange;

public:



/// Get the element type of a range.
template RangeElementType(alias T) if(isRange!T){
    alias RangeElementType = RangeElementType!(typeof(T));
}
/// ditto
template RangeElementType(T) if(isRange!T){
    alias RangeElementType = typeof(T.init.front);
}



unittest{
    struct IntRange{
        @property int front(){return 0;}
        void popFront(){}; enum bool empty = false;
    }
    struct CIntRange{
        @property const(int) front(){return 0;}
        void popFront(){}; enum bool empty = false;
    }
    struct StringRange{
        @property string front(){return null;}
        void popFront(){}; enum bool empty = false;
    }
    struct IntFieldRange{
        int front;
        void popFront(){}; enum bool empty = false;
    }
    IntRange ints;
    static assert(is(RangeElementType!ints == int));
    static assert(is(RangeElementType!IntRange == int));
    static assert(is(RangeElementType!CIntRange == const int));
    static assert(is(RangeElementType!StringRange == string));
}
