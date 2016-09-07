module mach.range.ngrams;

private:

import std.traits : Unqual;
import mach.traits : hasNumericLength, ElementType, isRange, isRandomAccessRange;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canNgram(Iter) = validAsRange!Iter;
enum canNgramRange(Range) = isRange!Range;

alias NgramSize = size_t;



/// Create a range which iterates the n-grams of its source range.
auto ngrams(NgramSize size, Iter)(Iter iter) if(canNgram!Iter){
    auto range = iter.asrange;
    return NgramRange!(typeof(range), size)(range);
}



struct NgramRange(Range, NgramSize size) if(canNgramRange!Range){
    alias Atom = Unqual!(ElementType!Range);
    alias Element = Atom[size];
    
    mixin MetaRangeMixin!(Range, `source`, `Empty`);
    
    this(typeof(this) range){
        this(range.source, range.front);
    }
    this(Range source){
        this.source = source;
        this.prepareFront();
    }
    this(Range source, Element front){
        this.source = source;
        this.front = front;
    }
    
    Range source;
    Element front;
    
    void prepareFront(){
        if(!this.source.empty){
            foreach(i; 0 .. size){
                if(i){
                    this.source.popFront();
                    if(this.source.empty) break;
                }
                this.front[i] = this.source.front;
            }
        }
    }
    void popFront(){
        this.source.popFront();
        if(!this.source.empty){
            foreach(i; 0 .. size - 1){
                this.front[i] = this.front[i + 1];
            }
            this.front[size - 1] = this.source.front;
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length + 1 - size;
        }
        alias opDollar = length;
    }
    
    static if(isRandomAccessRange!Range){
        auto ref opIndex(in size_t index) in{
            assert(index >= 0 && index < this.length);
        }body{
            Element element;
            foreach(i; 0 .. size){
                element[i] = this.source[i + index];
            }
            return element;
        }
    }
    
    // TODO: Slice
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Ngrams", {
        auto input = "hello";
        tests("Bigrams", {
            auto range = input.ngrams!2;
            testeq("Length", range.length, 4);
            test("Iteration", range.equals(["he", "el", "ll", "lo"]));
            testeq("Random access", range[1], "el");
        });
        tests("Trigrams", {
            auto range = input.ngrams!3;
            testeq("Length", range.length, 3);
            test("Iteration", range.equals(["hel", "ell", "llo"]));
            testeq("Random access", range[1], "ell");
        });
    });
}
