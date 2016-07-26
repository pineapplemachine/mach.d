module mach.range.skipindexes;

private:

import std.traits : isIntegral;
import mach.traits : isRange, isBidirectionalRange, hasNumericLength;
import mach.traits : ElementType, isIterableOf;
import mach.range.contains : contains;
import mach.range.meta : MetaRangeMixin;
import mach.range.asrange : asrange, validAsRange;

public:



alias DefaultSkipIndex = size_t;

enum validSkipIndex(Index) = isIntegral!Index;

enum canSkipIndexes(Iter, Index = DefaultSkipIndex) = (
    validAsRange!Iter && validSkipIndex!Index
);

enum canSkipIndexesRange(Range, Index = DefaultSkipIndex) = (
    isRange!Range && canSkipIndexes!(Range, Index)
);



auto skipindexes(Iter, Index = DefaultSkipIndex)(
    auto ref Iter iter, Index[] indexes...
) if(canSkipIndexes!(Iter, Index)){
    auto range = iter.asrange;
    return SkipIndexesRange!(typeof(range), Index)(range, indexes);
}

auto skipindexes(Iter, Indexes)(
    auto ref Iter iter, Indexes indexes
) if(canSkipIndexes!Iter && isIterableOf!(Indexes, validSkipIndex)){
    auto range = iter.asrange;
    return SkipIndexesRange!(typeof(range), ElementType!Indexes)(range, indexes);
}



auto skipindex(Iter, Index = DefaultSkipIndex)(
    auto ref Iter iter, Index index
) if(canSkipIndexes!(Iter, Index)){
    return skipindexes(iter, index);
}



struct SkipIndexesRange(Range, Index = DefaultSkipIndex) if(
    canSkipIndexesRange!(Range, Index)
){
    alias Indexes = Index[];
    static enum isBidirectional = (
        isBidirectionalRange!Range && hasNumericLength!Range
    );
    
    mixin MetaRangeMixin!(Range, `source`, `Empty Dollar Save`);
    
    Range source;
    Index frontindex;
    static if(isBidirectional) Index backindex;
    Indexes skips;
    
    static if(isBidirectional){
        this(typeof(this) range){
            this(range.source, range.skips, range.frontindex, range.backindex);
        }
        this(Range source, Indexes skips, Index frontindex = 0){
            this(source, skips, frontindex, cast(Index) source.length);
        }
        this(Range source, Indexes skips, Index frontindex, Index backindex){
            this.source = source;
            this.skips = skips;
            this.frontindex = frontindex;
            this.backindex = backindex;
            this.skipFront();
            this.skipBack();
        }
    }else{
        this(typeof(this) range){
            this(range.source, range.skips, range.frontindex);
        }
        this(Range source, Indexes skips, Index frontindex = 0){
            this.source = source;
            this.skips = skips;
            this.frontindex = frontindex;
            this.skipFront();
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length - this.skips.length;
        }
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.source.popFront();
        this.frontindex++;
        this.skipFront();
    }
    void skipFront(){
        while(this.skips.contains(this.frontindex)){
            this.source.popFront();
            this.frontindex++;
        }
    }
    
    static if(isBidirectional){
        @property auto ref back(){
            return this.source.back;
        }
        void popBack(){
            this.source.popBack();
            this.backindex--;
            this.skipBack();
        }
        void skipBack(){
            while(this.skips.contains(this.backindex)){
                this.source.popBack();
                this.backindex--;
            }
        }
    }
    
    // TODO: Slice
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Skip Indexes", {
        auto input = [0, 1, 2, 3, 4];
        test(input.skipindexes(1).equals([0, 2, 3, 4]));
        test(input.skipindexes(1, 3).equals([0, 2, 4]));
        test(input.skipindexes(1, 2, 3).equals([0, 4]));
        test(input.skipindexes(0, 4).equals([1, 2, 3]));
        test(input.skipindexes(0).equals([1, 2, 3, 4]));
        test(input.skipindexes(4).equals([0, 1, 2, 3]));
        test(input.skipindexes(0, 1, 2, 3, 4).equals(new int[0]));
        test(input.skipindexes().equals(input));
        test(input.skipindexes([1, 3]).equals([0, 2, 4]));
    });
}
