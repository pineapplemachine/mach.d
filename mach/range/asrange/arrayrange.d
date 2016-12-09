module mach.range.asrange.arrayrange;

private:

import mach.traits : ArrayElementType, isArray, isIntegral, canSliceSame;
import mach.error : enforcebounds;

public:



enum canMakeArrayRange(T) = isArray!T;



auto asarrayrange(Array)(Array array) if(canMakeArrayRange!Array){
    return ArrayRange!(Array)(array);
}



/// Range based on an array.
struct ArrayRange(Array) if(canMakeArrayRange!(Array)){
    alias Element = ArrayElementType!Array;
    
    enum bool mutable = is(typeof({this.array[0] = this.array[0];}));
    
    /// The array over which this range iterates.
    Array array;
    /// The index in the array where this range begins.
    size_t startindex;
    /// The index in the array where this range ends.
    size_t endindex;
    /// Index of the array where the front of the range is currently located,
    /// as modified by the range's startindex.
    size_t frontindex;
    /// Index of the array where the back of the range is currently located,
    /// as modified by the range's startindex.
    size_t backindex;
    
    this(Array array){
        this(array, frontindex, array.length);
    }
    this(Array array, size_t frontindex, size_t backindex){
        this(array, 0, backindex - frontindex, frontindex, backindex);
    }
    this(Array array, size_t frontindex, size_t backindex, size_t startindex, size_t endindex){
        this.array = array;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.startindex = startindex;
        this.endindex = endindex;
    }
    
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    @property auto ref front() in{assert(!this.empty);} body{
        return this.array[this.frontindex + this.startindex];
    }
    
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    @property auto ref back() in{assert(!this.empty);} body{
        return this.array[this.backindex + this.startindex - 1];
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto remaining() const{
        return this.backindex - this.frontindex;
    }
    @property auto length() const{
        return this.endindex - this.startindex;
    }
    alias opDollar = length;
    
    auto ref opIndex(in size_t index) in{
        enforcebounds(index, this);
    }body{
        return this.array[index + this.startindex];
    }
    
    typeof(this) opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        return typeof(this)(this.array, low + this.startindex, high + this.startindex);
    }
    
    @property typeof(this) save(){
        return this;
    }
    
    bool opEquals(in Array rhs) const{
        return this.array[this.startindex .. this.endindex] == rhs;
    }
    bool opEquals(in typeof(this) rhs) const{
        return (
            this.array[this.startindex .. this.endindex] ==
            rhs.array[rhs.startindex .. rhs.endindex]
        );
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.traits : isRange, isBidirectionalRange, isRandomAccessRange;
    import mach.traits : isSlicingRange, isSavingRange, hasNumericLength;
}
unittest{
    alias Range = ArrayRange!(int[]);
    static assert(isRange!Range);
    static assert(isBidirectionalRange!Range);
    static assert(isRandomAccessRange!Range);
    static assert(isSlicingRange!Range);
    static assert(isSavingRange!Range);
    static assert(hasNumericLength!Range);
    tests("Array as range", {
        tests("Equality", {
            auto range = ArrayRange!(int[])([1, 2, 3]);
            testeq(range, [1, 2, 3]);
            testeq(range, range);
        });
        tests("Saving", {
            auto range = ArrayRange!(int[])([1, 2, 3]);
            auto saved = range.save;
            while(!range.empty) range.popFront();
            testeq(range.frontindex, 3);
            testeq(saved.frontindex, 0);
        });
        tests("Slicing", {
            auto range = ArrayRange!(int[])([1, 1, 2, 3, 5, 8]);
            auto slice = range[1 .. 4];
            static assert(is(typeof(range) == typeof(slice)));
            testeq(slice.length, 3);
            testeq(slice[0], 1);
            testeq(slice[1], 2);
            testeq(slice[2], 3);
            testfail({range[0 .. $+1];});
            testfail({range[3 .. 1];});
        });
        tests("Random access", {
            auto range = ArrayRange!(int[])([1, 2, 3]);
            testeq(range[0], 1);
            testeq(range[1], 2);
            testeq(range[$-1], 3);
            testfail({range[$];});
        });
        tests("Empty", {
            auto range = ArrayRange!(int[])(new int[0]);
            testeq(range.length, 0);
            test(range.empty);
            testfail({range.front;});
            testfail({range.back;});
            testfail({range.popFront;});
            testfail({range.popBack;});
        });
        tests("Mutability", {
            char[] data = ['h', 'e', 'l', 'l', 'o'];
            auto range = ArrayRange!(char[])(data);
            static assert(range.mutable);
            range[1] = 'a';
            range.popFront();
            testeq(range.front, 'a');
            testeq(range.back, 'o');
            range.front = 'i';
            testeq(data[1], 'i');
            range.back = 's';
            testeq(data, "hills");
        });
        tests("Immutability", {
            tests("Const int", {
                const int[] data = [0, 1, 2];
                auto range = data.asarrayrange;
                static assert(!range.mutable);
                testeq(range[0], data[0]);
                testeq(range.front, data[0]);
                range.popFront();
                testeq(range.front, data[1]);
            });
            tests("Immutable members", {
                struct ConstMember{const int x;}
                auto data = [ConstMember(0), ConstMember(1)];
                auto range = data.asarrayrange;
                static assert(!range.mutable);
                testeq(range.front.x, 0);
                range.popFront();
                testeq(range.front.x, 1);
                range.popFront();
                test(range.empty);
            });
        });
        tests("Saving", {
            auto range = ArrayRange!(int[])([1, 2, 3]);
            auto saved = range.save;
            range.popFront();
            testeq(saved.front, 1);
            testeq(range.front, 2);
        });
        tests("Static array", {
            int[3] array = [1, 2, 3];
            auto range = ArrayRange!(int[3])(array);
            testeq(range.length, 3);
            testeq(range[0], 1);
            auto partial = range[0 .. 2];
            static assert(is(typeof(partial) == typeof(range)));
            testeq(partial.length, 2);
            testeq(partial[0], 1);
            testeq(partial[$-1], 2);
            auto full = range[0 .. $];
            testeq(full.length, 3);
        });
    });
}
