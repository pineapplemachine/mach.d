module mach.range.ends;

private:

import std.traits : isIntegral;
import mach.error.assertf : assertf;
import mach.traits : isRange, isBidirectionalRange, isRandomAccessRange, isSavingRange;
import mach.traits : isInfiniteIterable, isInfiniteRange, hasNumericLength;
import mach.range.asrange : asrange, validAsRange, validAsRandomAccessRange;

public:



alias validEndRangeCount = isIntegral;

enum canGetEnd(Iter, Count) = (
    validAsRandomAccessRange!Iter && hasNumericLength!Iter && validEndRangeCount!Count
);
enum canGetEndRange(Range, Count) = (
    isRandomAccessRange!Range && canGetEnd!(Range, Count)
);

enum canGetSimpleHead(Iter, Count) = (
    validAsRange!Iter && (
        hasNumericLength!Iter || isInfiniteIterable!Iter
    ) && validEndRangeCount!Count
);

enum canGetSimpleHeadRange(Range, Count) = (
    isRange!Range && canGetSimpleHead!(Range, Count)
);



/// Get as a range the first count elements of some iterable.
auto head(Iter, Count)(Iter iter, Count count) if(
    canGetSimpleHead!(Iter, Count) && !canGetEnd!(Iter, Count)
){
    auto range = iter.asrange;
    return SimpleHeadRange!(typeof(range), Count)(range, count);
}

/// ditto
auto head(Iter, Count)(Iter iter, Count count) if(canGetEnd!(Iter, Count)){
    auto range = iter.asrange;
    return HeadRange!(typeof(range), Count)(range, count);
}

/// Get as a range the trailing count elements of some iterable.
auto tail(Iter, Count)(Iter iter, Count count) if(canGetEnd!(Iter, Count)){
    auto range = iter.asrange;
    return TailRange!(typeof(range), Count)(range, count);
}



template HeadRange(Range, Count = size_t) if(canGetEndRange!(Range, Count)){
    alias HeadRange = EndRange!(Range, Count, false);
}

template TailRange(Range, Count = size_t) if(canGetEndRange!(Range, Count)){
    alias TailRange = EndRange!(Range, Count, true);
}



struct SimpleHeadRange(Range, Count = size_t) if(canGetSimpleHeadRange!(Range, Count)){
    Range source;
    Count index;
    Count limit;
    
    this(typeof(this) range){
        this(range.source, range.index, range.limit);
    }
    this(Range source, Count limit, Count index = Count.init){
        this.source = source;
        this.limit = limit;
        this.index = index;
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.index++;
        this.source.popFront();
    }
    
    @property bool empty(){
        return (this.index >= this.limit) || this.source.empty;
    }
    
    static if(isInfiniteRange!Range){
        alias length = limit;
    }else{
        @property auto length(){
            return this.source.length < this.limit ? this.source.length : this.limit;
        }
    }
    
    alias opDollar = length;
    
    static if(isSavingRange!Range){
        @property auto ref save(){
            return typeof(this)(this.source.save, this.limit, this.index);
        }
    }
}

struct EndRange(Range, Count = size_t, bool tail) if(canGetEndRange!(Range, Count)){
    Range source;
    Count frontindex;
    Count backindex;
    Count limit;
    
    alias index = frontindex;
    
    this(typeof(this) range){
        this(range.source, range.frontindex, range.backindex, range.limit);
    }
    this(Range source, Count limit, Count frontindex = Count.init){
        Count backindex = source.length < limit ? cast(Count) source.length : limit;
        this(source, limit, frontindex, backindex);
    }
    this(Range source, Count limit, Count frontindex, Count backindex){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.limit = limit;
    }
    
    @property auto ref front(){
        return this[this.frontindex];
    }
    void popFront(){
        this.frontindex++;
    }
    
    @property auto ref back(){
        return this[this.backindex - 1];
    }
    void popBack(){
        this.backindex--;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    
    @property auto length(){
        return this.source.length < this.limit ? this.source.length : this.limit;
    }

    alias opDollar = length;
    
    auto ref opIndex(Count index) in{
        assertf(
            index >= 0 && index < this.length,
            "Index %d is out of range [0, %d).",
            index, this.length
        );
    }body{
        static if(!tail){
            return this.source[index];
        }else{
            return this.source[this.source.length - this.length + index];
        }
    }
    
    // TODO: Slice
    
    static if(isSavingRange!Range){
        @property auto ref save(){
            return typeof(this)(
                this.source.save, this.limit, this.frontindex, this.backindex
            );
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    struct InfiniteRangeTest{
        int value;
        @property auto ref front() const{
            return this.value;
        }
        void popFront(){
            this.value++;
        }
        enum bool empty = false;
    }
}
unittest{
    import std.stdio;
    tests("Ends", {
        auto input = [1, 2, 3, 4, 5];
        tests("Simple head", {
            auto range = InfiniteRangeTest(5).head(3);
            testeq(range.length, 3);
            test(range.equals([5, 6, 7]));
        });
        tests("Head", {
            test(input.head(3).equals([1, 2, 3]));
            testeq("Random access", input.head(3)[0], 1);
        });
        tests("Tail", {
            test(input.tail(3).equals([3, 4, 5]));
            testeq("Random access", input.tail(3)[0], 3);
        });
    });
}
