module mach.range.asrange.indexrange;

private:

import std.traits : isIntegral;
import mach.traits : hasNumericIndex, hasNumericLength, canSliceSame;

public:



enum bool canMakeIndexRange(Base) = (
    hasNumericIndex!Base &&
    hasNumericLength!Base
);

enum bool canMakeIndexRange(Base, Index) = (
    canMakeIndexRange!Base &&
    isIntegral!Index
);



/// Make a range from some object implementing opIndex(Index) and length where
/// length is also of type Index and can be decremented. Start the front index
/// at Index.init and back index at length-1 and keep popping until the front
/// index exceeds the back index.
struct IndexRange(Base, Index = size_t) if(canMakeIndexRange!(Base, Index)){
    Base source;
    Index frontindex;
    Index backindex;
    
    this(typeof(this) range){
        this(range.source, range.frontindex, range.backindex);
    }
    this(Base source, Index frontindex = Index.init){
        this(source, frontindex, cast(Index) source.length);
    }
    this(Base source, Index frontindex, Index backindex){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto remaining() const{
        return this.backindex - this.frontindex;
    }
    
    @property auto length(){
        return this.basis.length;
    }
    alias opDollar = length;
    
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    @property auto ref front(){
        return this.source[this.frontindex];
    }
    
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    @property auto ref back(){
        auto index = this.backindex;
        index--;
        return this.source[index];
    }
    
    auto ref opIndex(Index index){
        return this.source[index];
    }
    
    static if(canSliceSame!(Base, Index)){
        typeof(this) opSlice(Index low, Index high){
            return typeof(this)(this.source[low .. high]);
        }
    }
    
    @property typeof(this) save() const{
        return typeof(this)(this);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    private struct Indexed{
        int value, length;
        auto opIndex(in int index) const{
            return this.value + index;
        }
        typeof(this) opSlice(in int low, in int high){
            return Indexed(low, high - low);
        }
    }
}
unittest{
    tests("Range from indexed type", {
        // TODO
    });
}

