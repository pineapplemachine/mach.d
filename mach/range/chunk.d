module mach.range.chunk;

private:

import std.traits : isIntegral;
import mach.math.round : ceil;
import mach.traits : isSlicingRange;
import mach.range.asrange : asrange, validAsSlicingRange;

public:



enum canChunk(Iter, Count) = (
    validAsSlicingRange!Iter && validAsChunkCount!Count
);

enum canChunkRange(Range, Count) = (
    isSlicingRange!Range && validAsChunkCount!Count
);

alias validAsChunkCount = isIntegral;

alias DefaultChunkCount = size_t;



/// Breaks down a single range into a range of smaller ranges. The final chunk
/// in the resulting range may be shorter than the provided size, but all others
/// will be that exact length.
auto chunk(Iter, Count = DefaultChunkCount)(Iter iter, Count size) if(
    canChunk!(Iter, Count)
){
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
    Range source; /// Making chunks from this range
    Count size; /// Maximum size of each chunk
    Count frontindex;
    Count backindex;
    
    this(Range source, Count size, Count frontindex = Count.init){
        this(source, size, frontindex, ceil(source.length, size));
    }
    this(Range source, Count size, Count frontindex, Count backindex){
        this.source = source;
        this.size = size;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property auto length(){
        return ceil(this.source.length, this.size);
    }
    @property bool empty(){
        return this.frontindex >= this.backindex;
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
    
    auto ref opIndex(in Count index){
        auto low = index * this.size;
        auto high = low + this.size;
        if(high > this.source.length) high = this.source.length;
        return this.source[low .. high];
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Chunk", {
        auto input = "abcdefghijklmnop";
        tests("Exact", {
            auto range = input.chunk(4);
            testeq(range.length, 4);
            test(range.equals(["abcd", "efgh", "ijkl", "mnop"]));
            test(range.equals(input.divide(range.length)));
        });
        tests("Nonexact", {
            auto range = input.chunk(5);
            testeq(range.length, 4);
            test(range.equals(["abcde", "fghij", "klmno", "p"]));
            tests("Divide", {
                auto input = "abcde";
                auto range = input.chunk(3);
                test(range.equals(input.divide(range.length)));
            });
        });
    });
}
