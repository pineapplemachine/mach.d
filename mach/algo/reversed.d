module mach.algo.reversed;

private:

import mach.algo.traits : hasLength, isSavingRange, isBidirectionalRange;
import mach.algo.asrange : asrange, validAsBidirectionalRange;

public:

alias canReverse = validAsBidirectionalRange;
alias canReverseRange = isBidirectionalRange;

auto reversed(Iter)(Iter iter) if(canReverse!Iter){
    auto range = iter.asrange;
    return ReversedRange!(typeof(range))(range);
}

struct ReversedRange(Range) if(canReverseRange!Range){
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
    
    @property bool empty(){
        return this.source.empty;
    }
    static if(hasLength!Range){
        @property auto length(){
            return this.source.length;
        }
        static if(hasBinaryOp(LengthType!Range, size_t, "-", LengthType!Range, size_t));
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
