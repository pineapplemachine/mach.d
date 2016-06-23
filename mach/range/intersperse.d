module mach.range.intersperse;

private:

import std.traits : isIntegral, isImplicitlyConvertible;
import mach.traits : isRange, isFiniteRange, isIterableOf, ElementType;
import mach.range.asrange : asrange, validAsRange;

public:



template canIntersperse(Iter, Element, Interval){
    static if(validAsRange!Iter && validIntersperseInterval!Interval){
        enum bool canIntersperse = (
            isImplicitlyConvertible!(Element, ElementType!Iter)
        );
    }else{
        enum bool canIntersperse = false;
    }
}

enum canIntersperseRange(Range, Interval) = (
    isRange!Range && canIntersperse!(Range, ElementType!Range, Interval)
);

alias validIntersperseInterval = isIntegral;

alias DefaultIntersperseInterval = size_t;



auto intersperse(
    bool frontinterval = false, bool backinterval = false,
    Iter, Element, Interval = DefaultIntersperseInterval
)(
    auto ref Iter iter, auto ref Element interrupt, Interval interval
) if(
    canIntersperse!(Iter, Element, Interval)
){
    auto range = iter.asrange;
    return IntersperseRange!(
        typeof(range), frontinterval, backinterval, Interval
    )(range, interrupt, interval);
}



struct IntersperseRange(
    Range, bool frontinterval = false, bool backinterval = false,
    Interval = DefaultIntersperseInterval
) if(canIntersperseRange!(Range, Interval)){
    alias Finite = isFiniteRange!Range;
    alias Element = ElementType!Range;
    
    Range source;
    Element interrupt;
    Interval interval;
    Interval index;

    this(Range source, Element interrupt, Interval interval, Interval index = 0){
        this.source = source;
        this.interrupt = interrupt;
        this.interval = interval;
        this.index = index;
    }
    
    static if(Finite){
        @property bool empty(){
            static if(backinterval){
                return !this.oninterrupt && this.source.empty;
            }else{
                return this.source.empty;
            }
        }
    }else{
        enum bool empty = false;
    }
    
    @property bool oninterrupt(){
        static if(frontinterval){
            return this.index == 0;
        }else{
            return this.index == (this.interval - 1);
        }
    }
    
    @property auto ref front(){
        return this.oninterrupt ? this.interrupt : this.source.front;
    }
    void popFront(){
        if(!this.oninterrupt) this.source.popFront();
        this.index = (this.index + 1) % this.interval;
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    static assert(canIntersperse!(string, char, size_t));
    static assert(canIntersperse!(int[], int, int));
    static assert(canIntersperse!(double[], int, size_t));
    static assert(!canIntersperse!(int[], string, size_t));
    tests("Intersperse", {
        test("hello".intersperse!(false, false)('_', 2).equals("h_e_l_l_o"));
        test("hello".intersperse!(true, false)('_', 2).equals("_h_e_l_l_o"));
        test("hello".intersperse!(false, true)('_', 2).equals("h_e_l_l_o_"));
        test("hello".intersperse!(true, true)('_', 2).equals("_h_e_l_l_o_"));
        test("hello".intersperse('_', 3).equals("he_ll_o"));
    });
}
