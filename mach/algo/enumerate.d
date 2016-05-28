module mach.algo.enumerate;

private:

import std.typecons : Tuple;
import mach.algo.traits : hasLength, canIncrement, hasBinaryOp, isSavingRange, ElementType;
import mach.algo.asrange : asrange, validAsRange;

public:



enum canEnumerateIndex(Index) = (
     canIncrement!Index && hasBinaryOp!(Index, "+")
);
enum canEnumerate(Iter, Index = size_t) = (
    validAsRange!Iter && canEnumerateIndex!Index
);
enum canEnumerateRange(Range, Index = size_t) = (
    isRange!Range && canEnumerateIndex!Index
);



auto enumerate(Index = size_t, Iter)(
    Iter iter, Index initial = Index.init
) if(canEnumerate!(Iter, Index)){
    auto range = iter.asrange;
    return EnumerationRange!(Index, typeof(range))(range, initial);
}
auto enumerate(Index = size_t, Iter)(
    Iter iter, Index initial, Index step
) if(canEnumerate!(Iter, Index)){
    auto range = iter.asrange;
    return EnumerationRange!(Index, typeof(range))(range, initial, step);
}



struct EnumerationRange(Index = size_t, Range) if(canEnumerateRange!(Range, Index)){
    alias Element = Tuple!(Index, "index", ElementType!Range, "value");
    
    Range source;
    Index step;
    Index index;
    
    this(typeof(this) range){
        this(range.source, range.step, range.index);
    }
    this(Range source, Index initial = Index.init){
        Index step = Index.init;
        step++;
        this(source, initial, step);
    }
    this(Range source, Index initial, Index step){
        this.source = source;
        this.index = initial;
        this.step = step;
    }
    
    @property auto front(){
        return Element(this.index, this.source.front);
    }
    void popFront(){
        this.source.popFront();
        this.index = this.index + this.step;
    }
    
    @property bool empty(){
        return this.source.empty;
    }
    static if(hasLength!Range){
        @property auto length(){
            return this.source.length;
        }
    }
    
    static if(isSavingRange!Range){
        @property auto save(){
            return typeof(this)(this.source.save);
        }
    }
}

unittest{
    // TODO
}
