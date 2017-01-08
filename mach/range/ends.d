module mach.range.ends;

private:

import mach.traits : isRange, isBidirectionalRange, isRandomAccessRange, isSavingRange;
import mach.traits : isInfiniteIterable, isInfiniteRange, hasNumericLength;
import mach.error : IndexOutOfBoundsError, InvalidSliceBoundsError;
import mach.range.asrange : asrange, validAsRange, validAsRandomAccessRange;

public:



enum canGetEnd(Iter) = (
    validAsRandomAccessRange!Iter && hasNumericLength!Iter
);
enum canGetEndRange(Range) = (
    isRandomAccessRange!Range && canGetEnd!Range
);

enum canGetSimpleHead(Iter) = (
    validAsRange!Iter
);

enum canGetSimpleHeadRange(Range) = (
    isRange!Range && canGetSimpleHead!Range
);

enum canGetHead(Iter) = (
    canGetEnd!Iter || canGetSimpleHead!Iter
);
enum canGetTail(Iter) = (
    canGetEnd!Iter
);



/// Get as a range the first count elements of some iterable.
auto head(Iter)(auto ref Iter iter, size_t count) if(
    canGetSimpleHead!(Iter) && !canGetEnd!(Iter)
){
    auto range = iter.asrange;
    return SimpleHeadRange!(typeof(range))(range, count);
}

/// ditto
auto head(Iter)(auto ref Iter iter, size_t count) if(canGetEnd!(Iter)){
    auto range = iter.asrange;
    return HeadRange!(typeof(range))(range, count);
}

/// Get as a range the trailing count elements of some iterable.
auto tail(Iter)(auto ref Iter iter, size_t count) if(canGetEnd!(Iter)){
    auto range = iter.asrange;
    return TailRange!(typeof(range))(range, count);
}



template HeadRange(Range) if(canGetEndRange!(Range)){
    alias HeadRange = EndRange!(Range, false);
}

template TailRange(Range) if(canGetEndRange!(Range)){
    alias TailRange = EndRange!(Range, true);
}



struct SimpleHeadRange(Range) if(canGetSimpleHeadRange!(Range)){
    Range source;
    size_t index;
    size_t limit;
    
    this(typeof(this) range){
        this(range.source, range.index, range.limit);
    }
    this(Range source, size_t limit, size_t index = size_t.init){
        this.source = source;
        this.limit = limit;
        this.index = index;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.source.front;
    }
    void popFront() in{assert(!this.empty);} body{
        this.index++;
        this.source.popFront();
    }
    
    @property bool empty(){
        return (this.index >= this.limit) || this.source.empty;
    }
    
    static if(isInfiniteRange!Range){
        alias length = limit;
        alias opDollar = length;
    }else static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length < this.limit ? this.source.length : this.limit;
        }
        alias opDollar = length;
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.limit, this.index);
        }
    }
}



struct EndRange(Range, bool tail) if(canGetEndRange!(Range)){
    Range source;
    size_t frontindex;
    size_t backindex;
    size_t limit;
    
    alias index = frontindex;
    
    this(typeof(this) range){
        this(range.source, range.frontindex, range.backindex, range.limit);
    }
    this(Range source, size_t limit, size_t frontindex = size_t.init){
        size_t backindex = source.length < limit ? cast(size_t)(source.length) : limit;
        this(source, limit, frontindex, backindex);
    }
    this(Range source, size_t limit, size_t frontindex, size_t backindex){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.limit = limit;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this[this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    
    @property auto back() in{assert(!this.empty);} body{
        return this[this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto length(){
        return this.source.length < this.limit ? this.source.length : this.limit;
    }

    alias opDollar = length;
    
    auto opIndex(in size_t index) in{
        static const error = new IndexOutOfBoundsError();
        error.enforce(index, this);
    }body{
        static if(!tail){
            return this.source[index];
        }else{
            return this.source[cast(size_t) this.source.length - this.length + index];
        }
    }
    
    auto opSlice(in size_t low, in size_t high) in{
        static const error = new InvalidSliceBoundsError();
        //error.enforce(low, high, this); // TODO: ??????????????????
        if(low < 0 || high < low || high > this.length) throw error;
    }body{
        static if(!tail){
            return this.source[low .. high];
        }else{
            immutable startindex = cast(size_t) this.source.length - this.length;
            return this.source[startindex + low .. startindex + high];
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(
                this.source.save, this.limit, this.frontindex, this.backindex
            );
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    struct InfiniteRangeTest{
        int value;
        enum bool empty = false;
        @property auto ref front(){return this.value;}
        void popFront(){this.value++;}
    }
}
unittest{
    // TODO: More thorough tests
    tests("Ends", {
        auto input = [1, 2, 3, 4, 5];
        tests("Simple head", {
            auto range = InfiniteRangeTest(5).head(3);
            testeq(range.length, 3);
            test(range.equals([5, 6, 7]));
        });
        tests("Head", {
            test(input.head(3).equals([1, 2, 3]));
            testeq(input.head(3)[0], 1);
            //tests("Slicing", {
                auto range = [0, 1, 2, 3, 4, 5, 6].head(4);
                test(range[0 .. 0].empty);
                test(range[$ .. $].empty);
                test!equals(range[0 .. 1], [0]);
                test!equals(range[0 .. 2], [0, 1]);
                test!equals(range[0 .. $], [0, 1, 2, 3]);
                test!equals(range[1 .. $], [1, 2, 3]);
                test!equals(range[3 .. $], [3]);
                //testfail({range[0 .. $+1];});
            //});
        });
        tests("Tail", {
            test(input.tail(3).equals([3, 4, 5]));
            testeq(input.tail(3)[0], 3);
        });
    });
}
