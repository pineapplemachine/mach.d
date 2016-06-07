module mach.range.tap;

private:

import mach.traits : isRange, isBidirectionalRange, isSavingRange, isSlicingRange;
import mach.traits : isIterable;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



alias canTap = isIterable;
alias canTapRange = isRange;



auto tap(alias func, Iter)(Iter iter) if(canTap!Iter){
    auto range = iter.asrange;
    return TapRange!(func, typeof(range))(range);
}



struct TapRange(alias func, Range) if(canTapRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar Save`,
    );
    
    Range source;
    
    this(typeof(this) range){
        this(range.source);
    }
    this(Range source){
        this.source = source;
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        func(this.source.front);
        this.source.popFront();
    }
    
    static if(isBidirectionalRange!Range){
        @property auto ref back(){
            return this.source.back;
        }
        void popBack(){
            func(this.source.back);
            this.source.popBack();
        }
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
    tests("Tap", {
        auto helloworld = "hello world";
        string forwards = "";
        string backwards = "";
        auto range = helloworld.tap!((ch){
            forwards ~= ch;
            backwards = ch ~ backwards;
        });
        testeq("Length", range.length, helloworld.length);
        while(!range.empty) range.popFront();
        testeq(forwards, helloworld);
        testeq(backwards, "dlrow olleh");
    });
}
