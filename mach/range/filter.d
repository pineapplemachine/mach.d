module mach.range.filter;

private:

import std.range.primitives : isForwardRange, isBidirectionalRange;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



/// Given an object that can be taken as a range, create a new range which
/// enumerates only those values of the original range matching some predicate.
auto filter(alias pred, Iter)(Iter iter) if(validAsRange!Iter){
    auto range = iter.asrange;
    return FilterRange!(pred, typeof(range))(range);
}



struct FilterRange(alias pred, Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `Empty Save Back`,
        `
            return this.source.front;
        `, `
            this.source.popFront();
            this.consumeFront();
        `
    );
    
    Range source;
    
    this(Range source){
        this.source = source;
        this.consumeFront();
        static if(isBidirectionalRange!Range) this.consumeBack();
    }
    
    /// Pop values from source range until a matching value is found.
    void consumeFront(){
        while(!this.source.empty && !pred(this.source.front)){
            this.source.popFront();
        }
    }
    
    static if(isBidirectionalRange!Range){
        void consumeBack(){
            while(!this.source.empty && !pred(this.source.back)){
                this.source.popBack();
            }
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Filter", {
        test([1, 2, 3, 4, 5, 6].filter!((n) => (n % 2 == 0)).equals([2, 4, 6]));
    });
}
