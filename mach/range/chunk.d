module mach.range.chunk;

private:

import mach.math.round : divceil;
import mach.traits : hasNumericLength, isSlicingRange, isSavingRange;
import mach.range.asrange : asrange, validAsSlicingRange;

public:



enum canChunk(Iter) = (
    validAsSlicingRange!Iter && hasNumericLength!Iter
);

enum canChunkRange(Range) = (
    isSlicingRange!Range && hasNumericLength!Range
);



/// Breaks down a single range into a range of smaller ranges. The final chunk
/// in the resulting range may be shorter than the provided size, but all others
/// will be that exact length.
auto chunk(Iter)(auto ref Iter iter, size_t size) if(canChunk!Iter)in{
    assert(size > 0);
}body{
    auto range = iter.asrange;
    return ChunkRange!(typeof(range))(range, size);
}



struct ChunkRange(Range) if(canChunkRange!(Range)){
    Range source; /// Make chunks from this range
    size_t size; /// Maximum size of each chunk
    size_t frontindex;
    size_t backindex;
    
    this(Range source, size_t size, size_t frontindex = size_t.init) in{
        assert(size > 0);
    }body{
        this(source, size, frontindex, divceil(source.length, size));
    }
    this(Range source, size_t size, size_t frontindex, size_t backindex) in{
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
        return divceil(cast(size_t) this.source.length, this.size);
    }
    alias opDollar = length;
    
    @property auto ref front() in{assert(!this.empty);} body{
        return this[this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    
    @property auto ref back() in{assert(!this.empty);} body{
        return this[this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    auto ref opIndex(in size_t index) in{
        assert(index >= 0 && index < this.length);
    }body{
        auto low = index * this.size;
        auto high = low + this.size;
        if(high > this.source.length) high = cast(size_t)(this.source.length);
        return this.source[low .. high];
    }
    
    typeof(this) opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        if(this.source.length){
            size_t slicelow = low * this.size;
            size_t slicehigh = high * this.size;
            if(slicelow > this.source.length - 1){
                slicelow = cast(size_t)(this.source.length - 1);
            }
            if(slicehigh > this.source.length){
                slicehigh = cast(size_t)(this.source.length);
            }
            return typeof(this)(this.source[slicelow .. slicehigh], this.size);
        }else{
            return typeof(this)(this.source[0 .. $], this.size);
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(
                this.source.save, this.size, this.frontindex, this.backindex
            );
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.retro : retro;
}
unittest{
    tests("Chunk", {
        auto input = "abcdefghijklmnop";
        tests("Exact", {
            auto range = input.chunk(4);
            testeq(range.length, 4);
            tests("Iteration", {
                range.equals(["abcd", "efgh", "ijkl", "mnop"]);
            });
            tests("Backwards", {
                range.retro.equals(["mnop", "ijkl", "efgh", "abcd"]);
            });
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
        tests("Inexact", {
            auto range = input.chunk(5);
            testeq(range.length, 4);
            tests("Iteration", {
                range.equals(["abcde", "fghij", "klmno", "p"]);
            });
            tests("Backwards", {
                range.retro.equals(["p", "klmno", "fghij", "abcde"]);
            });
        });
    });
}
