module mach.algo.enumerate;

private:

import std.range.primitives : isForwardRange, ElementType;
import std.typecons : Tuple;
import mach.algo.traits : hasLength, canIncrement, hasBinaryOp;
import mach.algo.asrange : asrange, validAsRange;

public:

enum canEnumerate(Iter, Index = size_t) = (
    validAsRange!Iter && canIncrement!Index && hasBinaryOp!(Index, "+")
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

struct EnumerationRange(Index = size_t, Base) if(canEnumerate!(Base, Index)){
    alias Elem = Tuple!(Index, "index", ElementType!Base, "value");
    
    Base source;
    Index step;
    Index index;
    
    this(typeof(this) range){
        this(range.source, range.step, range.index);
    }
    this(Base source, Index initial = Index.init){
        Index step = Index.init;
        step++;
        this(source, initial, step);
    }
    this(Base source, Index initial, Index step){
        this.source = source;
        this.index = index;
        this.step = step;
    }
    
    @property auto front(){
        return Elem(this.index, this.source.front);
    }
    void popFront(){
        this.source.popFront();
        this.index = this.index + this.step;
    }
    
    @property bool empty(){
        return this.source.empty;
    }
    static if(hasLength!Base){
        @property auto length(){
            return this.source.length;
        }
    }
    
    static if(isForwardRange!Base){
        @property auto save(){
            return typeof(this)(this.source.save);
        }
    }
}

unittest{
    // TODO
}
