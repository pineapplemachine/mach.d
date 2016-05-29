module mach.range.reversed;

private:

import std.traits : Unqual, isNumeric;
import mach.traits : canCast, hasLength, LengthType, isBidirectionalRange;
import mach.traits : SingleIndexParameter, hasSingleIndexParameter, isTemplateOf;
import mach.range.asrange : asrange, validAsBidirectionalRange;
import mach.range.metarange : MetaRangeMixin;

public:



alias canReverse = validAsBidirectionalRange;
alias canReverseRange = isBidirectionalRange;

enum isReversedRange(Range) = isTemplateOf!(Range, ReversedRange);



auto reversed(Iter)(Iter iter) if(canReverse!Iter){
    static if(!isReversedRange!Iter){
        auto range = iter.asrange;
        return ReversedRange!(typeof(range))(range);
    }else{
        // Dont re-reverse an already reversed range
        return iter.source;
    }
}



struct ReversedRange(Range) if(canReverseRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`, `RandomAccess Slice`
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
    
    static if(hasLength!Range && isNumeric!(LengthType!Range)){
        // TODO: Slices
        
        alias Len = Unqual!(LengthType!Range);
        
        static if(hasSingleIndexParameter!Range && canCast!(Len, SingleIndexParameter!Range)){
            auto opIndex(Len index){
                return this.source[
                    cast(SingleIndexParameter!Range) this.source.length - index - 1
                ];
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
        test(input.reversed.equals([3, 2, 1, 0]));
        tests("Random access", {
            testeq(input.reversed[0], 3);
            testeq(input.reversed[3], 0);
            testeq(input.reversed[$-1], 0);
        });
        // TODO: Slices
    });
}
