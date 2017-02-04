module mach.range.meta;

private:

import mach.traits : isRange;

public:



/// Used for ranges whose empty property should be
/// the same as the source range if it has one.
template MetaRangeEmptyMixin(Range, string source = `source`) if(isRange!Range){
    import mach.traits : hasEmptyEnum;
    static if(hasEmptyEnum!Range){
        alias empty = Range.empty;
    }else{
        @property bool empty(){
            mixin(`return this.` ~ source ~ `.empty;`);
        }
    }
}

/// Used for ranges whose length, remaining, and opDollar properties should be
/// the same as the source range if it has them.
template MetaRangeLengthMixin(Range, string source = `source`) if(isRange!Range){
    import mach.traits : hasLength, hasRemaining, hasDollar;
    static if(hasLength!Range){
        @property auto length(){
            mixin(`return this.` ~ source ~ `.length;`);
        }
    }
    static if(hasRemaining!Range){
        @property auto remaining(){
            mixin(`return this.` ~ source ~ `.remaining;`);
        }
    }
    static if(hasDollar!Range){
        @property auto opDollar(){
            mixin(`return this.` ~ source ~ `.opDollar;`);
        }
    }
}
