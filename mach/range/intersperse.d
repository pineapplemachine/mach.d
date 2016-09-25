module mach.range.intersperse;

private:

import std.traits : isIntegral, isImplicitlyConvertible;
import mach.traits : isRange, isFiniteRange, isIterableOf, ElementType;
import mach.range.asrange : asrange, validAsRange;

public:



template canIntersperse(Iter, Element){
    static if(validAsRange!Iter){
        enum bool canIntersperse = (
            isImplicitlyConvertible!(Element, ElementType!Iter)
        );
    }else{
        enum bool canIntersperse = false;
    }
}

enum canIntersperseRange(Range) = (
    isRange!Range && canIntersperse!(Range, ElementType!Range)
);

alias IntersperseInterval = size_t;



auto intersperse(
    bool frontinterval = false, bool backinterval = false,
    Iter, Element
)(
    auto ref Iter iter, auto ref Element interrupt, IntersperseInterval interval
) if(
    canIntersperse!(Iter, Element)
){
    auto range = iter.asrange;
    return IntersperseRange!(
        typeof(range), frontinterval, backinterval
    )(range, interrupt, interval);
}



struct IntersperseRange(
    Range, bool frontinterval, bool backinterval
) if(canIntersperseRange!(Range)){
    alias Element = ElementType!Range;
    alias Interval = IntersperseInterval;
    enum bool isFinite = isFiniteRange!Range;
    
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
    
    static if(isFinite){
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
    import mach.test;
    import mach.range.asrange : asrange;
    import mach.range.compare : equals;
}
unittest{
    static assert(canIntersperse!(string, char));
    static assert(canIntersperse!(int[], int));
    static assert(canIntersperse!(double[], int));
    static assert(!canIntersperse!(int[], string));
    tests("Intersperse", {
        tests("Strings", {
            test("hello".intersperse!(false, false)('_', 2).equals("h_e_l_l_o"));
            test("hello".intersperse!(true, false)('_', 2).equals("_h_e_l_l_o"));
            test("hello".intersperse!(false, true)('_', 2).equals("h_e_l_l_o_"));
            test("hello".intersperse!(true, true)('_', 2).equals("_h_e_l_l_o_"));
            test("hello".intersperse('_', 3).equals("he_ll_o"));
            test(["a", "b", "cd"].intersperse("_", 2).equals(["a", "_", "b", "_", "cd"]));
        });
        tests("Ranges", {
            test("hello".asrange.intersperse('_', 2).equals("h_e_l_l_o"));
            test(["a", "b", "cd"].asrange.intersperse("_", 2).equals(["a", "_", "b", "_", "cd"]));
        });
    });
}
