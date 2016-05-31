module mach.range.callback;

private:

import mach.traits : isRange, isBidirectionalRange, isSavingRange, isSlicingRange;
import mach.traits : isIterable;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



alias canCallback = isIterable;
alias canCallbackRange = isRange;



auto callback(alias func, Iter)(Iter iter) if(canCallback!Iter){
    auto range = iter.asrange;
    return CallbackRange!(func, typeof(range))(range);
}



struct CallbackRange(alias func, Range) if(canCallbackRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar Save Back`,
        `
            return this.source.front;
        `, `
            func(front);
            this.source.popFront();
        `
    );
    
    Range source;
    
    this(typeof(this) range){
        this(range.source);
    }
    this(Range source){
        this.source = source;
    }
    
    static if(isSlicingRange!Range){
        typeof(this) opSlice(in size_t low, in size_t high){
            return typeof(this)(this.source[low .. high]);
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Callback", {
        auto helloworld = "hello world";
        string forwards = "";
        string backwards = "";
        auto range = helloworld.callback!((ch){
            forwards ~= ch;
            backwards = ch ~ backwards;
        });
        testeq("Length", range.length, helloworld.length);
        while(!range.empty) range.popFront();
        testeq(forwards, helloworld);
        testeq(backwards, "dlrow olleh");
    });
}
