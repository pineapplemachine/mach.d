module mach.range.chunk;

private:

import std.conv : to;
import std.traits : isIntegral;
import mach.math.round : ceil;
import mach.traits : hasNumericLength, isSlicingRange;
import mach.range.asrange : asrange, validAsSlicingRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canChunk(Iter, Count) = (
    validAsSlicingRange!Iter && hasNumericLength!Iter && validAsChunkCount!Count
);

enum canChunkRange(Range, Count) = (
    isSlicingRange!Range && hasNumericLength!Range && validAsChunkCount!Count
);

alias validAsChunkCount = isIntegral;

alias DefaultChunkCount = size_t;



/// Breaks down a single range into a range of smaller ranges. The final chunk
/// in the resulting range may be shorter than the provided size, but all others
/// will be that exact length.
auto chunk(Iter, Count = DefaultChunkCount)(Iter iter, Count size) if(
    canChunk!(Iter, Count)
)in{
    assert(size > 0);
}body{
    auto range = iter.asrange;
    return ChunkRange!(typeof(range), Count)(range, size);
}

/// Divides a single range into a range of smaller ranges, given a number of
/// such smaller ranges to produce.
auto divide(Iter, Count = DefaultChunkCount)(Iter iter, Count count) if(
    canChunk!(Iter, Count)
){
    return chunk(iter, ceil(iter.length, count));
}



struct ChunkRange(Range, Count = DefaultChunkCount) if(
    canChunkRange!(Range, Count)
){
    mixin MetaRangeMixin!(
        Range, `source`, `Save`
    );
    
    Range source; /// Making chunks from this range
    Count size; /// Maximum size of each chunk
    Count frontindex;
    Count backindex;
    
    this(Range source, Count size, Count frontindex = Count.init) in{
        assert(size > 0);
    }body{
        this(source, size, frontindex, ceil(source.length, size));
    }
    this(Range source, Count size, Count frontindex, Count backindex) in{
        assert(size > 0);
    }body{
        this.source = source;
        this.size = size;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property bool empty(){
        return this.frontindex >= this.backindex;
    }
    @property auto remaining(){
        return this.backindex - this.frontindex;
    }
    @property auto length(){
        return ceil(this.source.length, this.size);
    }
    alias opDollar = length;
    
    @property auto ref front(){
        return this[this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    
    @property auto ref back(){
        return this[this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    auto ref opIndex(in size_t index){
        auto low = index * this.size;
        auto high = low + this.size;
        if(high > this.source.length) high = to!Count(this.source.length);
        return this.source[low .. high];
    }
    
    typeof(this) opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        if(this.source.length){
            size_t slicelow = low * this.size;
            size_t slicehigh = high * this.size;
            if(slicelow > this.source.length - 1){
                slicelow = to!size_t(this.source.length - 1);
            }
            if(slicehigh > this.source.length){
                slicehigh = to!size_t(this.source.length);
            }
            return typeof(this)(this.source[slicelow .. slicehigh], this.size);
        }else{
            return typeof(this)(this.source[0 .. $], this.size);
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.retro : retro;
}
unittest{
    tests("Chunk", {
        auto input = "abcdefghijklmnop";
        tests("Exact", {
            auto range = input.chunk(4);
            testeq("Length", range.length, 4);
            test("Iteration",
                range.equals(["abcd", "efgh", "ijkl", "mnop"])
            );
            test("Backwards",
                range.retro.equals(["mnop", "ijkl", "efgh", "abcd"])
            );
            test("Divide",
                range.equals(input.divide(range.length))
            );
            tests("Random access", {
                test(range[0].equals("abcd"));
                test(range[1].equals("efgh"));
                test(range[2].equals("ijkl"));
                test(range[$-1].equals("mnop"));
            });
            tests("Slicing", {
                test(range[0 .. $].equals(range));
                test(range[0 .. 1].equals(["abcd"]));
                test(range[1 .. 3].equals(["efgh", "ijkl"]));
            });
            tests("Saving", {
                auto copy = range.save;
                copy.popFront();
                test(range.front.equals("abcd"));
                test(copy.front.equals("efgh"));
            });
        });
        tests("Nonexact", {
            auto range = input.chunk(5);
            testeq("Length", range.length, 4);
            test("Iteration",
                range.equals(["abcde", "fghij", "klmno", "p"])
            );
            test("Backwards",
                range.retro.equals(["p", "klmno", "fghij", "abcde"])
            );
            tests("Divide", {
                auto input = "abcde";
                auto range = input.chunk(3);
                test(range.equals(input.divide(range.length)));
            });
        });
    });
}
