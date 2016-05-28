module mach.algo.reversed;

private:

import std.range.primitives : isForwardRange;
import mach.algo.traits : hasLength;
import mach.algo.asrange : asrange, validAsBidirectionalRange;

public:

alias canReverse = validAsBidirectionalRange;

auto reversed(Iter)(Iter iter) if(canReverse!Iter){
    auto range = iter.asrange;
    return ReversedRange!(typeof(range))(range);
}

struct ReversedRange(Base) if(canReverse!Base){
    Base source;
    
    this(Base source){
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
