module mach.range.asrange.indexrange;

private:

import std.traits : isIntegral;
import mach.traits : hasNumericIndex, hasNumericLength, canSliceSame;

public:



alias DefaultIndexRangeIndex = size_t;

alias validIndexRangeIndex = isIntegral;

template canMakeIndexRange(Subject, Index = DefaultIndexRangeIndex){
    enum bool canMakeIndexRange = (
        hasNumericIndex!Subject && validIndexRangeIndex!Index
    );
}



auto asindexrange(Subject, Index = DefaultIndexRangeIndex)(auto ref Subject subject) if(
    canMakeIndexRange!(Subject, Index)
){
    return IndexRange!(Subject, Index)(subject);
}



struct IndexRange(
    Subject, Index = DefaultIndexRangeIndex
){
    alias isBidirectional = hasNumericLength!Subject;
    
    Subject subject;
    Index frontindex;
    static if(isBidirectional) Index backindex;
    
    this(Subject subject, Index frontindex = 0){
        static if(isBidirectional){
            this(subject, frontindex, subject.length);
        }else{
            this.subject = subject;
            this.frontindex = frontindex;
        }
    }
    static if(isBidirectional){
        this(Subject subject, Index frontindex, Index backindex){
            this.subject = subject;
            this.frontindex = frontindex;
            this.backindex = backindex;
        }
        @property auto length(){
            return this.subject.length;
        }
        alias opDollar = length;
        @property bool empty(){
            return this.frontindex >= this.backindex;
        }
        @property auto back() in{assert(!this.empty);} body{
            return this.subject[this.backindex - 1];
        }
        void popBack() in{assert(!this.empty);} body{
            this.backindex--;
        }
    }else{
        enum bool empty = false;
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return this.subject[frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    auto opIndex(Index index){
        return this.subject[index];
    }
    
    static if(canSliceSame!Subject){
        typeof(this) opSlice(Index low, Index high){
            return typeof(this)(this.subject[low .. high]);
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.subject, this.frontindex, this.backindex);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Index Range", {
        auto input = "hello";
        auto range = input.asindexrange;
        testeq("Length", range.length, input.length);
        testeq(range.front, input[0]);
        testeq(range.back, input[$-1]);
        testeq("Random access", range[1], input[1]);
        test("Slicing", range[1 .. $-1].equals(input[1 .. $-1]));
        size_t i = 0;
        foreach(e; range) testeq(e, input[i++]);
    });
}
