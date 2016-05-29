module mach.range.enumerate;

private:

import std.traits : isImplicitlyConvertible;
import mach.traits : canIncrement, canDecrement, canCast, ElementType;
import mach.traits : isRange, isRandomAccessRange, hasLength, LengthType;
import mach.traits : hasSingleIndexParameter, SingleIndexParameter;
import mach.range.asrange : asrange, validAsRange;
import mach.range.metarange : MetaRangeMixin;

public:



enum canEnumerateIndex(Index) = canIncrement!Index;
enum canEnumerateIndexBidirectional(Index) = (
    canEnumerateIndex!Index && canDecrement!Index
);

enum canEnumerate(Iter, Index = size_t) = (
    validAsRange!Iter && canEnumerateIndex!Index
);
enum canEnumerateRange(Range, Index = size_t) = (
    isRange!Range && canEnumerateIndex!Index
);
enum canEnumerateRangeBidirectional(Range, Index = size_t) = (
    isRange!Range && canEnumerateIndexBidirectional!Index &&
    hasLength!Range && canCast!(LengthType!Range, Index)
);



auto enumerate(Index = size_t, Iter)(
    Iter iter, Index initial = Index.init
) if(canEnumerate!(Iter, Index)){
    auto range = iter.asrange;
    return EnumerationRange!(Index, typeof(range))(range, initial);
}



struct EnumerationRangeElement(Index, Value){
    Index index;
    Value value;
    
    // Because who doesn't like shorthand
    alias idx = index;
    alias i = index;
    alias val = value;
    alias v = val;
    
    this(typeof(this) element){
        this(element.index, element.value);
    }
    this(Index index, Value value){
        this.index = index;
        this.value = value;
    }
}
struct EnumerationRange(Index = size_t, Range) if(canEnumerateRange!(Range, Index)){
    alias Element = EnumerationRangeElement!(Index, ElementType!Range);
    
    static enum bool isBidirectional = canEnumerateRangeBidirectional!(Range, Index);
    
    mixin MetaRangeMixin!(
        Range, `source`, `RandomAccess Slice`
    );
    
    Range source;
    Index frontindex;
    static if(isBidirectional) Index backindex;
    
    this(typeof(this) range){
        static if(isBidirectional){
            this(range.source, range.frontindex, range.backindex);
        }else{
            this(range.source, range.frontindex);
        }
    }
    this(Range source, Index frontinitial = Index.init){
        static if(isBidirectional){
            Index backinitial = cast(Index) source.length;
            backinitial--;
            this(source, frontinitial, backinitial);
        }else{
            this.source = source;
            this.frontindex = frontinitial;
        }
    }
    static if(isBidirectional){
        this(Range source, Index frontinitial, Index backinitial){
            this.source = source;
            this.frontindex = frontinitial;
            this.backindex = backinitial;
        }
    }
    
    @property auto front(){
        return Element(this.frontindex, this.source.front);
    }
    void popFront(){
        this.source.popFront();
        this.frontindex++;
    }
    static if(isBidirectional){
        @property auto back(){
            return Element(this.backindex, this.source.back);
        }
        void popBack(){
            this.source.popBack();
            this.backindex--;
        }
    }
    
    static if(
        isRandomAccessRange!Range &&
        hasSingleIndexParameter!Range &&
        isImplicitlyConvertible!(SingleIndexParameter!Range, Index)
    ){
        auto opIndex(Index index){
            return Element(index, this.source[index]);
        }
    }
    
    // TODO: Slice
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.pluck : pluck;
}
unittest{
    tests("Enumerate", {
        auto input = ["ant", "bat", "cat", "dot", "eel"];
        testeq(input.enumerate[1].value, input[1]);
        test(input.enumerate.pluck!`index`.equals([0, 1, 2, 3, 4]));
        test(input.enumerate.pluck!`value`.equals(input));
    });
}