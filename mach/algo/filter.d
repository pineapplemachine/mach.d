module mach.algo.filter;

private:

import std.range.primitives : isForwardRange, isBidirectionalRange;
import mach.algo.asrange : asrange, validAsRange;

public:

/// Given an object that can be taken as a range, create a new range which
/// enumerates only those values of the original range matching some predicate.
auto filter(alias pred, Iter)(Iter iter) if(validAsRange!Iter){
    auto range = iter.asrange;
    return FilterRange!(pred, typeof(range))(range);
}

struct FilterRange(alias pred, Range){
    Range source;
    
    this(Range source){
        this.source = source;
        this.consume();
        static if(isBidirectionalRange!Range) this.consumeback();
    }
    
    @property auto front(){
        return this.source.front;
    }
    void popFront(){
        this.source.popFront();
        this.consume();
    }
    
    /// Pop values from source range until a matching value is found.
    void consume(){
        while(!this.source.empty && !pred(this.source.front)){
            this.source.popFront();
        }
    }
    
    @property bool empty(){
        return this.source.empty;
    }
    
    static if(isBidirectionalRange!Range){
        @property auto back(){
            return this.source.back;
        }
        void popBack(){
            this.source.popBack();
            this.consumeback();
        }
        void consumeback(){
            while(!this.source.empty && !pred(this.source.back)){
                this.source.popBack();
            }
        }
    }
    static if(isForwardRange!Range){
        @property auto save(){
            return typeof(this)(this.source.save);
        }
    }
}

unittest{
    // TODO
}
