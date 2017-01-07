module mach.range.chunk;

private:

import mach.meta : varmin;
import mach.traits : hasNumericLength, isSlicingRange, isSavingRange;
import mach.range.asrange : asrange, validAsSlicingRange;
import mach.math.round : divceil;

/++ Docs

The `chunk` function returns a range for enumerating sequential chunks of an
input, its first argument being the input iterable and its second argument being
the size of the chunks to produce.
If the iterable is not evenly divisible by the given chunk size, then the
final element of the chunk range will be shorter than the given size.

The input iterable must support slicing and have numeric length. The outputted
range is bidirectional, has `length` and `remaining` properties, allows random
access and slicing operations, and can be saved.

+/

unittest{ /// Example
    auto range = "abc123xyz!!".chunk(3);
    assert(range.length == 4);
    assert(range[0] == "abc");
    assert(range[1] == "123");
    assert(range[2] == "xyz");
    // Final chunk is shorter because the input wasn't evenly divisble by 3.
    assert(range[3] == "!!");
}

public:



/// Determine whether the `chunk` function can be applied to some type.
enum canChunk(T) = (
    hasNumericLength!T && is(typeof({
        size_t low, high;
        auto slice = T.init[low .. high];
    }))
);



/// Get a range for lazily enumerating chunks of a sliceable input.
auto chunk(T)(auto ref T iter, size_t size) if(canChunk!T) in{
    assert(size > 0);
}body{
    return ChunkRange!T(iter, size);
}



/// Range for lazily enumerating chunks of an input.
struct ChunkRange(Source) if(canChunk!Source){
    /// Input to be chunked.
    Source source;
    /// Maximum size of each chunk.
    size_t size;
    /// Cursor representing the front of the range.
    size_t frontindex;
    /// Cursor representing the back of the range.
    size_t backindex;
    
    this(Source source, size_t size, size_t frontindex = 0) in{
        assert(size > 0);
    }body{
        this(source, size, frontindex, divceil(source.length, size));
    }
    
    this(Source source, size_t size, size_t frontindex, size_t backindex) in{
        assert(size > 0);
    }body{
        this.source = source;
        this.size = size;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    
    @property auto length(){
        return divceil(cast(size_t) this.source.length, this.size);
    }
    alias opDollar = length;
    
    @property auto remaining() const{
        return this.backindex - this.frontindex;
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
    
    auto opIndex(in size_t index) in{
        assert(index >= 0 && index < this.length);
    }body{
        immutable low = index * this.size;
        immutable high = varmin(low + this.size, cast(size_t) this.source.length);
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
    
    /// Save the range.
    /// Assumes slicing and random access do not modify the range's content.
    @property typeof(this) save(){
        return typeof(this)(
            this.source, this.size, this.frontindex, this.backindex
        );
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
