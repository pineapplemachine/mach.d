module mach.range.retro;

private:

import std.traits : Unqual, isNumeric;
import mach.traits : isBidirectionalRange, isRandomAccessRange, hasNumericLength;
import mach.traits : isSlicingRange, canCast, isTemplateOf;
import mach.range.asrange : asrange, validAsBidirectionalRange;
import mach.range.meta : MetaRangeMixin;

public:



alias canRetro = validAsBidirectionalRange;
alias canRetroRange = isBidirectionalRange;

enum isRetroRange(Range) = isTemplateOf!(Range, RetroRange);



/// Return a range which iterates over some iterable in reverse-order.
auto retro(Iter)(Iter iter) if(canRetro!Iter){
    static if(!isRetroRange!Iter){
        auto range = iter.asrange;
        return RetroRange!(typeof(range))(range);
    }else{
        // Dont re-reverse an already reversed range
        return iter.source;
    }
}



struct RetroRange(Range) if(canRetroRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar Save`
    );
    
    Range source;
    
    this(Range source){
        this.source = source;
    }
    
    @property auto front(){
        return this.source.back;
    }
    void popFront(){
        this.source.popBack();
    }
    
    @property auto back(){
        return this.source.front;
    }
    void popBack(){
        this.source.popFront();
    }
    
    static if(hasNumericLength!Range){
        static if(isRandomAccessRange!Range){
            auto opIndex(size_t index){
                return this.source[this.source.length - index - 1];
            }
        }
        static if(isSlicingRange!Range){
            typeof(this) opSlice(size_t low, size_t high){
                auto sourcelow = this.source.length - high;
                auto sourcehigh = this.source.length - low;
                return typeof(this)(this.source[sourcelow .. sourcehigh]);
            }
        }
    }
}



version(unittest){
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Reversed", {
        auto input = [0, 1, 2, 3];
        test(input.retro.equals([3, 2, 1, 0]));
        tests("Random access", {
            testeq(input.retro[0], 3);
            testeq(input.retro[3], 0);
            testeq(input.retro[$-1], 0);
        });
        tests("Slicing", {
            import std.stdio;
            test(input.retro[0 .. $-1].equals([3, 2, 1]));
            test(input.retro[1 .. $-1].equals([2, 1]));
            test(input.retro[1 .. $].equals([2, 1, 0]));
        });
    });
}