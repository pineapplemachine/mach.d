module mach.traits.element.range;

private:

import mach.traits.range : isRange;

public:



/// Get the element type of a range.
template RangeElementType(T) if(isRange!T){
    alias RangeElementType = typeof(T.init.front);
}



version(unittest){
    private:
    struct IntFrontRange{
        enum bool empty = false;
        @property int front(){return 0;}
        void popFront(){};
    }
    struct ConstIntRange{
        enum bool empty = false;
        @property const(int) front(){return 0;}
        void popFront(){};
    }
    struct StringFrontRange{
        enum bool empty = false;
        @property string front(){return null;}
        void popFront(){};
    }
    struct IntFieldRange{
        enum bool empty = false;
        int front;
        void popFront(){};
    }
}

unittest{
    static assert(is(RangeElementType!IntFrontRange == int));
    static assert(is(RangeElementType!ConstIntRange == const int));
    static assert(is(RangeElementType!StringFrontRange == string));
    static assert(is(RangeElementType!IntFieldRange == int));
}
