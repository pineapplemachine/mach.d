module mach.range.ngrams;

private:

import mach.traits : hasNumericLength, hasNumericRemaining;
import mach.traits : ElementType, isRange, isRandomAccessRange;
import mach.traits : isSlicingRange, isSavingRange;
import mach.range.asrange : asrange, validAsRange;
import mach.range.asstaticarray : asstaticarray;
import mach.range.rangeof : EmptyRangeOf;
import mach.range.meta : MetaRangeMixin;

/++ Docs

The `ngrams` function can be used to generate n-grams given an input iterable.
The length of each n-gram is given as a template argument: Calling `ngrams!2`
enumerates bigrams, `ngrams!3` enumerates trigrams, and so on.

The elements of a range produced by `ngrams` are static arrays containing
a number of elements equal to the count specified using the function's
template argument.

+/

unittest{ /// Example
    assert("hello".ngrams!2.equals(["he", "el", "ll" ,"lo"]));
}

/++ Docs

One of the more practical uses for this function is to generate n-grams
from a sequence of words.

+/

unittest{ /// Example
    import mach.range.split : split;
    auto text = "hello how are you";
    auto words = text.split(' ');
    auto bigrams = words.ngrams!2;
    assert(bigrams.equals([["hello", "how"], ["how", "are"], ["are", "you"]]));
}

/++ Docs

When the input passed to `ngrams` provides `length` and `remaining` properties,
so does the outputted range. Infiniteness is similarly propagated.
When the input supports random access and slicing operations, so does the output.

+/

unittest{ /// Example
    auto range = [0, 1, 2, 3].ngrams!2;
    assert(range.length == 3);
    assert(range[0] == [0, 1]);
}

public:



enum canNgram(Iter) = validAsRange!Iter;
enum canNgramRange(Range) = isRange!Range;



/// Create a range which iterates the n-grams of its source range.
auto ngrams(size_t size, Iter)(Iter iter) if(canNgram!Iter){
    static if(size <= 0){
        EmptyRangeOf!(ElementType!Iter[0]) range;
        return range;
    }else static if(size == 1){
        return iter;
    }else{
        auto range = iter.asrange;
        return NgramRange!(typeof(range), size)(range);
    }
}



struct NgramRange(Range, size_t size) if(size > 0 && canNgramRange!Range){
    alias Element = ElementType!Range;
    alias History = Element[];
    
    mixin MetaRangeMixin!(Range, `source`, `Empty`);
    
    Range source;
    History history;
    
    this(Range source){
        this.source = source;
        this.prepareFront();
    }
    this(Range source, History history){
        this.source = source;
        this.history = history;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.history.asstaticarray!size;
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
        if(!this.source.empty){
            this.history = this.history[1 .. $];
            this.history ~= this.source.front;
        }
    }
    
    /// Called at initialization to consume and store the input
    /// up to the end of the first n-gram.
    private void prepareFront(){
        size_t i = 0;
        while(!this.source.empty && i++ < size){
            this.history ~= this.source.front;
            if(i < size) this.source.popFront();
        }
    }
    
    static if(hasNumericLength!Range){
        /// Get the length of the range.
        @property auto length(){
            return cast(size_t) this.source.length + 1 - size;
        }
        /// ditto
        alias opDollar = length;
    }
    static if(hasNumericRemaining!Range){
        /// Get the number of elements remaining in the range.
        @property auto remaining(){
            return cast(size_t) this.source.remaining + 2 - size;
        }
    }
    
    static if(isRandomAccessRange!Range){
        /// Get the element at an index.
        auto opIndex(in size_t index) in{
            assert(index >= 0 && index < this.length);
        }body{
            return this.source[index .. index + size].asstaticarray!size;
        }
    }
    
    static if(isSlicingRange!Range){
        auto opSlice(in size_t low, in size_t high) in{
            assert(low >= 0 && high >= low && high <= this.length);
        }body{
            if(high == low){
                // Optimization for empty slice.
                // Benefit becomes apparent where `prepareFront` is required
                // to consume fewer elements to initialize the produced range.
                return typeof(this)(this.source[low .. high]);
            }else{
                return typeof(this)(this.source[low .. high + size - 1]);
            }
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.history.dup);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("N-grams", {
        tests("Empty input", {
            auto range = new int[0].ngrams!2;
            test(range.empty);
        });
        tests("Iteration", {
            auto range = [0, 1, 2, 3].ngrams!2;
            testf(range.empty);
            testeq(range.length, 3);
            testeq(range.remaining, 3);
            testeq(range.front, [0, 1]);
            range.popFront();
            testeq(range.length, 3);
            testeq(range.remaining, 2);
            testeq(range.front, [1, 2]);
            range.popFront();
            testeq(range.remaining, 1);
            testeq(range.front, [2, 3]);
            range.popFront();
            testeq(range.remaining, 0);
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront();});
        });
        tests("Random access", {
            auto range = [0, 1, 2, 3].ngrams!2;
            testeq(range[0], [0, 1]);
            testeq(range[1], [1, 2]);
            testeq(range[$-1], [2, 3]);
            testfail({range[$];});
        });
        tests("Slicing", {
            auto range = [0, 1, 2, 3].ngrams!2;
            tests("Empty slice", {
                test(range[0 .. 0].empty);
                test(range[1 .. 1].empty);
                test(range[$ .. $].empty);
                testfail({range[$+1 .. $+1];});
            });
            tests("Not empty", {
                test!equals(range[0 .. 1], [[0, 1]]);
                test!equals(range[0 .. 2], [[0, 1], [1, 2]]);
                test!equals(range[0 .. $], [[0, 1], [1, 2],  [2, 3]]);
                test!equals(range[1 .. $], [[1, 2],  [2, 3]]);
                test!equals(range[2 .. $], [[2, 3]]);
                testfail({range[0 .. $+1];});
            });
        });
        tests("Saving", {
            auto range = [0, 1, 2, 3].ngrams!2;
            range.popFront();
            auto saved = range.save;
            saved.popFront();
            testeq(range.front, [1, 2]);
            testeq(saved.front, [2, 3]);
        });
        tests("Trigrams", {
            auto range = "hello".ngrams!3;
            testeq(range.length, 3);
            test(range.equals(["hel", "ell", "llo"]));
            testeq(range[1], "ell");
        });
    });
}
