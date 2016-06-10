module mach.range.stride;

private:

import std.traits : isIntegral;
import mach.traits : isRange, isRandomAccessRange, isSlicingRange;
import mach.traits : isBidirectionalRange, hasEmptyEnum, hasNumericLength;
import mach.range.asrange : asrange, validAsRange, validAsRandomAccessRange;
import mach.range.meta : MetaRangeMixin;

public:



alias DefaultStride = size_t;
alias validAsStride = isIntegral;

enum canStride(Iter, Stride) = validAsRange!Iter && validAsStride!Stride;
enum canStrideRange(Range, Stride) = isRange!Range && validAsStride!Stride;

enum canRandomAccessStrideRange(Range) = (
    isRandomAccessRange!Range && !hasEmptyEnum!Range && hasNumericLength!Range
);

enum isStrideRange(Range) = (
    isPoppingStrideRange!Range || isRandomAccessStrideRange!Range
);
enum isPoppingStrideRange(Range) = (
    isTemplateOf!(Range, RandomAccessStrideRange)
);
enum isRandomAccessStrideRange(Range) = (
    isTemplateOf!(Range, RandomAccessStrideRange)
);



auto stride(Iter, Stride = DefaultStride)(
    Iter iter, Stride stride
) if(canStride!(Iter, Stride)) in{
    assert(stride > 0);
}body{
    auto range = iter.asrange;
    static if(canRandomAccessStrideRange!(typeof(range))){
        return RandomAccessStrideRange!(typeof(range), Stride)(range, stride);
    }else{
        return PoppingStrideRange!(typeof(range), Stride)(range, stride);
    }
}



struct RandomAccessStrideRange(Range, Stride = DefaultStride){
    mixin MetaRangeMixin!(
        Range, `source`, `Save`
    );
    
    Range source;
    Stride stride;
    Stride frontindex;
    Stride backindex;
    
    alias index = frontindex;
    
    this(typeof(this) range){
        this(range.source, range.stride, range.frontindex, range.backindex);
    }
    this(Range source, Stride stride, Stride frontindex = Stride.init) in{
        assert(stride > 0);
    }body{
        Stride backindex = cast(Stride) (source.length / stride);
        backindex += backindex * stride < source.length;
        this(source, stride, frontindex, backindex);
    }
    this(Range source, Stride stride, Stride frontindex, Stride backindex) in{
        assert(stride > 0);
    }body{
        this.source = source;
        this.stride = stride;
        this.frontindex = frontindex;
        this.backindex = backindex;
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
        auto floorlen = source.length / stride;
        return floorlen + (floorlen * stride < source.length);
    }
    alias opDollar = length;
    
    auto ref opIndex(in size_t index) in{
        assert(index >= 0 && index < this.length);
    }body{
        return this.source[index * this.stride];
    }
    
    static if(isSlicingRange!Range){
        typeof(this) opSlice(in size_t low, in size_t high) in{
            assert(low >= 0 && high >= low && high <= this.length);
        }body{
            return typeof(this)(
                this.source[low * stride .. high * stride], this.stride
            );
        }
    }
}



struct PoppingStrideRange(Range, Stride = DefaultStride){
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Save`
    );
    
    enum bool isBidirectional = (
        isBidirectionalRange!Range && hasNumericLength!Range
    );
    
    Range source;
    Stride stride;
    
    static if(isBidirectional){
        bool preparedback;
        this(typeof(this) range){
            this(range.source, range.stride, range.preparedback);
        }
        this(Range source, Stride stride, bool preparedback = false) in{
            assert(stride > 0);
        }body{
            this.source = source;
            this.stride = stride;
            this.preparedback = preparedback;
        }
    }else{
        this(typeof(this) range){
            this(range.source, range.stride);
        }
        this(Range source, Stride stride) in{
            assert(stride > 0);
        }body{
            this.source = source;
            this.stride = stride;
        }
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        for(Stride i = Stride.init; i < this.stride && !this.source.empty; i++){
            this.source.popFront();
        }
    }
    
    static if(isBidirectional){
        @property auto ref back(){
            if(!this.preparedback) this.prepareBack();
            return this.source.back;
        }
        void popBack(){
            if(!this.preparedback) this.prepareBack();
            for(Stride i = Stride.init; i < this.stride && !this.source.empty; i++){
                this.source.popBack();
            }
        }
        /// Pop elements from the back to get a consistent range frontwards and backwards
        void prepareBack(){
            auto pop = (this.source.length - (this.source.length > 0)) % this.stride;
            for(Stride i = Stride.init; i < pop; i++){
                this.source.popBack();
            }
            this.preparedback = true;
        }
    }
    
    @property auto length(){
        return this.source.length / this.stride + (
            this.source.length % this.stride > 0
        );
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.retro : retro;
    struct PoppingStrideTest(T){
        T array;
        size_t frontindex, backindex;
        this(T array){
            this.array = array;
            this.frontindex = 0;
            this.backindex = array.length;
        }
        @property auto ref front(){
            return this.array[this.frontindex];
        }
        void popFront(){
            this.frontindex++;
        }
        @property auto ref back(){
            return this.array[this.backindex - 1];
        }
        void popBack(){
            this.backindex--;
        }
        @property bool empty(){
            return this.frontindex >= this.backindex;
        }
        @property auto length(){
            return this.array.length;
        }
    }
}
unittest{
    tests("Stride", {
        tests("With random access", {
            tests("Iteration", {
                test("0123456".stride(1).equals("0123456"));
                test("0123456".stride(2).equals("0246"));
                test("01234567".stride(2).equals("0246"));
            });
            tests("Bidirectionality", {
                auto range = "012345".stride(2).retro;
                testeq(range.length, 3);
                test(range.equals("420"));
            });
            tests("Disallow stride < 1", {
                fail({"xyz".stride(0);});
                fail({"xyz".stride(-1);});
            });
            tests("Length", {
                testeq("0123".stride(1).length, 4);
                testeq("0123".stride(2).length, 2);
                testeq("0123".stride(3).length, 2);
                testeq("0123".stride(4).length, 1);
                testeq("0123".stride(5).length, 1);
            });
            tests("Random access", {
                auto range = "abcdefg".stride(2);
                testeq(range[0], 'a');
                testeq(range[1], 'c');
                testeq(range[2], 'e');
                testeq(range[$-1], 'g');
            });
            tests("Slicing", {
                test("0123456".stride(2)[1 .. $-1].equals("24"));
            });
        });
        tests("Without random acccess", {
            tests("Iteration", {
                auto range = PoppingStrideTest!string("hello world");
                test(range.stride(1).equals("hello world"));
                test(range.stride(2).equals("hlowrd"));
                test(range.stride(3).equals("hlwl"));
            });
            tests("Length", {
                auto range1 = PoppingStrideTest!string("hello world");
                testeq(range1.stride(1).length, 11);
                testeq(range1.stride(2).length, 6);
                testeq(range1.stride(3).length, 4);
                auto range2 = PoppingStrideTest!string("hello worlds");
                testeq(range2.stride(1).length, 12);
                testeq(range2.stride(2).length, 6);
                testeq(range2.stride(3).length, 4);
            });
            tests("Bidirectionality", {
                tests("Backwards iteration", {
                    auto source1 = PoppingStrideTest!string("hello world");
                    test(source1.stride(2).retro.equals("drwolh"));
                    test(source1.stride(3).retro.equals("lwlh"));
                    auto source2 = PoppingStrideTest!string("hello worlds");
                    test(source2.stride(2).retro.equals("drwolh"));
                    test(source2.stride(3).retro.equals("lwlh"));
                });
                tests("Combination", {
                    auto range = PoppingStrideTest!string("abcdefg").stride(2);
                    test(range.equals("aceg"));
                    testeq(range.front, 'a');
                    testeq(range.back, 'g');
                    range.popFront();
                    testeq(range.front, 'c');
                    testeq(range.back, 'g');
                    range.popBack();
                    testeq(range.front, 'c');
                    testeq(range.back, 'e');
                    range.popFront();
                    testeq(range.front, 'e');
                    testeq(range.back, 'e');
                    range.popBack();
                    test(range.empty);
                });
            });
        });
    });
}
