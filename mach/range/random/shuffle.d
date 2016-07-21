module mach.range.random.shuffle;

private:

import std.traits : Unqual, isIntegral;
import mach.traits : ElementType, hasNumericLength, isFiniteIterable, isFiniteRange, isInfiniteRange;
import mach.range.random.xorshift : XorshiftRange, xorshift;
import mach.range.random.seed : seeds;

public:



// References:
// https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_.22inside-out.22_algorithm



enum canShuffle(Iter) = (
    isFiniteIterable!Iter
);

template canShuffle(Iter, RNG){
    static if(canShuffle!Iter && isInfiniteRange!RNG){
        enum bool canShuffle = isIntegral!(ElementType!RNG);
    }else{
        enum bool canShuffle = false;
    }
}



alias shuffle = shuffleeager;



/// Eagerly constructs an array which contains the members of the source
/// iterable in a random order.
auto shuffleeager(Iter)(Iter iter) if(canShuffle!Iter){
    static XorshiftRange!size_t rng;
    static bool seeded = false;
    if(!seeded){
        rng.seed(seeds!(size_t, typeof(rng).seeds));
        seeded = true;
    }
    return shuffleeager(iter, rng);
}

/// ditto
auto shuffleeager(Iter, RNG)(Iter iter, RNG rng) if(canShuffle!(Iter, RNG)){
    alias Element = Unqual!(ElementType!Iter);
    alias KnownLength = hasNumericLength!Iter;
    static if(KnownLength){
        Element[] array = new Element[iter.length];
    }else{
        Element[] array;
    }
    size_t i = 0;
    foreach(element; iter){
        size_t j = rng.random!size_t(i + 1);
        rng.popFront();
        if(j == i){
            static if(KnownLength) array[i] = element;
            else array ~= element;
        }else{
            static if(KnownLength) array[i] = array[j];
            else array ~= array[j];
            array[j] = element;
        }
        i++;
    }
    return array;
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.logical : exactly;
    import mach.range.recur : recur;
}
unittest{
    tests("Shuffle", {
        tests("Known length range", {
            auto input = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            auto output = input.shuffleeager;
            testeq(output.length, 10);
            foreach(element; input){
                test(output.exactly(element, 1));
            }
        });
        tests("Unknown length range", {
            auto input = recur!((int n) => (n + 1), ((n) => (n >= 10))); // Increment n until n >= 10
            auto output = input.shuffleeager;
            testeq(output.length, 10);
            foreach(element; input){
                test(output.exactly(element, 1));
            }
        });
    });
}
