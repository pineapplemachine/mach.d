module mach.range.cartpower;

private:

import mach.meta : Repeat, varmap;
import mach.traits : ElementType, hasNumericLength, hasNumericRemaining;
import mach.traits : isFiniteRange, isSavingRange, isRandomAccessRange;
import mach.error : IndexOutOfBoundsError;
import mach.range.asrange : asrange, validAsSavingRange;

/++ Docs

The `cartpower` function produces a range that is the [n-ary Cartesian product]
(https://en.wikipedia.org/wiki/Cartesian_product#n-ary_product)
of an input iterable with itself.
It accepts a single input iterable that is valid as a saving range to perform
the operation upon, and an unsigned integer representing the dimensionality of
the exponentiation as a template argument.

+/

unittest{ /// Example
    import mach.types : tuple;
    import mach.range.compare : equals;
    assert(cartpower!2([1, 2, 3]).equals([
        tuple(1, 1), tuple(1, 2), tuple(1, 3),
        tuple(2, 1), tuple(2, 2), tuple(2, 3),
        tuple(3, 1), tuple(3, 2), tuple(3, 3),
    ]));
}

/++ Docs

The function accepts an optional template argument deciding whether outputs
containing the same elements in different orders should be considered
duplicates, and the duplicates omitted.
The two options are `CartesianPowerType.Ordered` and `CartesianPowerType.Unordered`.

+/

unittest{
    import mach.types : tuple;
    import mach.range.compare : equals;
    // Outputted tuples are considered ordered; that is, (a, b) and (b, a) are unique.
    assert(cartpower!(2, CartesianPowerType.Ordered)([1, 2]).equals([
        tuple(1, 1), tuple(1, 2),
        tuple(2, 1), tuple(2, 2),
    ]));
    // Outputted tuples are unordered; that is, (b, a) is omitted because it duplicates (a, b).
    assert(cartpower!(2, CartesianPowerType.Unordered)([1, 2]).equals([
        tuple(1, 1), tuple(1, 2),
        tuple(2, 2),
    ]));
}

public:



/// Distinguish between whether `cartpower` ranges should consider
/// outputs containing the same elements in a different order equivalent and
/// so omit them.
/// For example, an ordered combinations range includes both (a, b) and (b, a)
/// whereas an unordered combinations range includes only one of two.
enum CartesianPowerType: bool{
    Ordered = true,
    Unordered = false
}



/// Get a range representing the n-ary Cartesian product of an iterable with
/// itself.
auto cartpower(
    size_t size, CartesianPowerType type = CartesianPowerType.Ordered, Iter
)(auto ref Iter iter) if(validAsSavingRange!Iter){
    auto range = iter.asrange;
    static if(type is CartesianPowerType.Ordered){
        return OrderedCombinationsRange!(typeof(range), size)(range);
    }else{
        return UnorderedCombinationsRange!(typeof(range), size)(range);
    }
}



/// Enumerate ordered combinations of elements of a given length given an
/// input range.
/// Combinations are ordered as in (a, b) and (b, a) are both included.
struct OrderedCombinationsRange(Source, size_t size) if(
    isFiniteRange!Source && isSavingRange!Source
){
    alias Sources = Repeat!(size, Source);
    
    Source source;
    Sources sources;
    size_t countconsumed = 0;
    
    this(Source source){
        this.source = source;
        foreach(i, _; this.sources){
            this.sources[i] = source.save();
        }
    }
    this(Source source, Sources sources, in size_t countconsumed){
        this.source = source;
        this.sources = sources;
        this.countconsumed = countconsumed;
    }
    
    static if(size > 0) @property bool empty(){
        return this.sources[0].empty;
    }
    @property auto front() in{assert(!this.empty);} body{
        return this.sources.varmap!(r => r.front);
    }
    void popFront() in{assert(!this.empty);} body{
        this.countconsumed++;
        foreach_reverse(i, _; this.sources){
            this.sources[i].popFront();
            static if(i > 0){
                if(this.sources[i].empty){
                    this.sources[i] = this.source.save();
                }else{
                    return;
                }
            }
        }
    }
    
    @property auto consumedFront() const{
        return this.countconsumed;
    }
    alias consumed = consumedFront;
    
    static if(size == 0){
        static enum bool empty = true;
        static enum size_t length = 0;
        static enum size_t remaining = 0;
    }else{
        static if(hasNumericLength!Source){
            /// Get the length of the range.
            /// Will overflow when length cannot fit in a `size_t` primitive.
            @property auto length(){
                return cast(size_t) this.source.length ^^ size;
            }
            /// Get the number of elements remaining in the range.
            /// Will overflow when length cannot fit in a `size_t` primitive.
            @property auto remaining(){
                return this.length - this.consumed;
            }
        }
    }
    alias opDollar = length;
    
    @property typeof(this) save(){
        return typeof(this)(
            this.source, this.sources.varmap!(s => s.save).expand, this.countconsumed
        );
    }
    
    static if(isRandomAccessRange!Source && hasNumericLength!Source){
        auto opIndex(in size_t index) in{
            static const error = new IndexOutOfBoundsError();
            error.enforce(index, this);
        }body{
            immutable size_t length = this.source.length;
            Repeat!(size, size_t) indexes = void;
            size_t x = index;
            foreach_reverse(i, _; this.sources){
                static if(i == 0){
                    version(unittest) assert(x < length); // Verify assumption
                    indexes[i] = x;
                }else{
                    indexes[i] = x % length;
                    x /= length;
                }
            }
            return indexes.varmap!(i => this.source[i]);
        }
    }
}



/// Enumerate unordered combinations of elements of a given length given an
/// input range.
/// Combinations are unordered as in only one of (a, b) or (b, a) are included.
struct UnorderedCombinationsRange(Source, size_t size) if(
    isFiniteRange!Source && isSavingRange!Source
){
    alias Sources = Repeat!(size, Source);
    
    Sources sources;
    size_t countconsumed = 0;
    
    this(Source source){
        static if(size > 0){
            this.sources[0] = source.save;
            foreach(i, _; this.sources[1 .. $]){
                this.sources[i + 1] = source.save();
            }
        }
    }
    this(Sources sources, in size_t countconsumed){
        this.sources = sources;
        this.countconsumed = countconsumed;
    }
    
    static if(size > 0) @property bool empty(){
        return this.sources[0].empty;
    }
    @property auto front() in{assert(!this.empty);} body{
        return this.sources.varmap!(r => r.front);
    }
    void popFront() in{assert(!this.empty);} body{
        this.countconsumed++;
        foreach_reverse(i, _; this.sources){
            this.sources[i].popFront();
            if(!this.sources[i].empty){
                foreach(j, __; this.sources[i + 1 .. $]){
                    this.sources[j + i + 1] = this.sources[i].save();
                }
                return;
            }
        }
    }
    
    @property auto consumedFront() const{
        return this.countconsumed;
    }
    alias consumed = consumedFront;
    
    // TODO: Random access
    
    static if(size == 0){
        static enum bool empty = true;
        static enum size_t length = 0;
        static enum size_t remaining = 0;
    }else{
        static if(hasNumericLength!Source){
            /// Get the length of the range.
            /// Will overflow when length cannot fit in a `size_t` primitive.
            @property auto length(){
                return unorderedlength!size(this.sources[0].length);
            }
            /// Get the number of elements remaining in the range.
            /// Will overflow when length cannot fit in a `size_t` primitive.
            @property auto remaining(){
                return this.length - this.consumed;
            }
        }
    }
    alias opDollar = length;
    
    @property typeof(this) save(){
        static if(size == 0){
            return this;
        }else{
            return typeof(this)(
                this.sources.varmap!(s => s.save).expand, this.countconsumed
            );
        }
    }
}

/// Compute the length of a `UnorderedCombinationsRange` given an input length
/// and output tuple size.
/// TODO: Can this be expressed without using recursion?
static private size_t unorderedlength(size_t size)(in size_t ilen){
    static if(size == 0){
        return ilen > 0 ? 1 : 0;
    }else static if(size == 1){
        return ilen;
    }else static if(size == 2){
        // Same as `ilen + unorderedlength!size(ilen - 1)`
        // And as `ilen * (ilen + 1) / 2`, but without overflow
        immutable x = ilen + 1;
        return (ilen / 2) * x + ((ilen & 1) * x) / 2;
    }else{
        if(ilen <= 1){
            return ilen;
        }else{
            return unorderedlength!(size)(ilen - 1) + unorderedlength!(size - 1)(ilen);
        }
    }
}



private version(unittest){
    import mach.test;
    import mach.types : tuple;
    import mach.meta : Aliases;
    import mach.range.next : next;
    import mach.range.compare : equals;
    alias sizes = Aliases!(0, 1, 2, 3, 4, 5, 6, 7, 8);
    alias Types = Aliases!(CartesianPowerType.Ordered, CartesianPowerType.Unordered);
}

unittest{ /// Zero-length input
    auto empty = new int[0];
    foreach(Type; Types){
        foreach(size; sizes[0 .. $]){ // Zero-length input
            test(empty.cartpower!(size, Type).empty);
        }
    }
}

unittest{ /// Single-length input
    auto empty = new int[0];
    foreach(Type; Types){
        foreach(size; sizes[1 .. $]){
            auto range = [5].cartpower!(size, Type);
            testf(range.empty);
            testeq(range.length, 1);
            auto element = range.front;
            static assert(element.length == size);
            foreach(value; element) testeq(value, 5);
            range.popFront();
            test(range.empty);
        }
    }
}

unittest{ /// Tuple foreach syntax
    foreach(Type; Types){
        foreach(x, y; [1, 2, 3].cartpower!(2, Type)){}
    }
}

unittest{ /// Ordered combinations, size == 2
    auto range = [1, 2].cartpower!(2, CartesianPowerType.Ordered);
    testf(range.empty);
    testeq(range.length, 4);
    testeq(range.remaining, 4);
    testeq(range.next, tuple(1, 1));
    testeq(range.length, 4);
    testeq(range.remaining, 3);
    testeq(range.next, tuple(1, 2));
    testeq(range.remaining, 2);
    testeq(range.next, tuple(2, 1));
    testeq(range.remaining, 1);
    testeq(range.next, tuple(2, 2));
    testeq(range.remaining, 0);
    test(range.empty);
    testfail({range.front;});
    testfail({range.popFront();});
    testeq(range[0], tuple(1, 1));
    testeq(range[1], tuple(1, 2));
    testeq(range[2], tuple(2, 1));
    testeq(range[$-1], tuple(2, 2));
    testfail({range[$];});
}

unittest{ /// More ordered combinations
    test!equals([1, 2, 3, 4].cartpower!(2, CartesianPowerType.Ordered), [
        tuple(1, 1), tuple(1, 2), tuple(1, 3), tuple(1, 4),
        tuple(2, 1), tuple(2, 2), tuple(2, 3), tuple(2, 4),
        tuple(3, 1), tuple(3, 2), tuple(3, 3), tuple(3, 4),
        tuple(4, 1), tuple(4, 2), tuple(4, 3), tuple(4, 4),
    ]);
    test!equals([1, 2].cartpower!(3, CartesianPowerType.Ordered), [
        tuple(1, 1, 1), tuple(1, 1, 2),
        tuple(1, 2, 1), tuple(1, 2, 2),
        tuple(2, 1, 1), tuple(2, 1, 2),
        tuple(2, 2, 1), tuple(2, 2, 2),
    ]);
    test!equals([1, 2, 3].cartpower!(3, CartesianPowerType.Ordered), [
        tuple(1, 1, 1), tuple(1, 1, 2), tuple(1, 1, 3),
        tuple(1, 2, 1), tuple(1, 2, 2), tuple(1, 2, 3),
        tuple(1, 3, 1), tuple(1, 3, 2), tuple(1, 3, 3),
        tuple(2, 1, 1), tuple(2, 1, 2), tuple(2, 1, 3),
        tuple(2, 2, 1), tuple(2, 2, 2), tuple(2, 2, 3),
        tuple(2, 3, 1), tuple(2, 3, 2), tuple(2, 3, 3),
        tuple(3, 1, 1), tuple(3, 1, 2), tuple(3, 1, 3),
        tuple(3, 2, 1), tuple(3, 2, 2), tuple(3, 2, 3),
        tuple(3, 3, 1), tuple(3, 3, 2), tuple(3, 3, 3),
    ]);
}

unittest{ /// Unordered combinations, size == 2
    auto range = [1, 2].cartpower!(2, CartesianPowerType.Unordered);
    testf(range.empty);
    testeq(range.length, 3);
    testeq(range.remaining, 3);
    testeq(range.next, tuple(1, 1));
    testeq(range.length, 3);
    testeq(range.remaining, 2);
    testeq(range.next, tuple(1, 2));
    testeq(range.remaining, 1);
    testeq(range.next, tuple(2, 2));
    testeq(range.remaining, 0);
    test(range.empty);
    testfail({range.front;});
    testfail({range.popFront();});
}

unittest{ /// More unordered combinations
    test!equals([1, 2, 3, 4].cartpower!(2, CartesianPowerType.Unordered), [
        tuple(1, 1), tuple(1, 2), tuple(1, 3), tuple(1, 4),
        tuple(2, 2), tuple(2, 3), tuple(2, 4),
        tuple(3, 3), tuple(3, 4),
        tuple(4, 4),
    ]);
    test!equals([1, 2].cartpower!(3, CartesianPowerType.Unordered), [
        tuple(1, 1, 1), tuple(1, 1, 2),
        tuple(1, 2, 2),
        tuple(2, 2, 2),
    ]);
    test!equals([1, 2, 3].cartpower!(3, CartesianPowerType.Unordered), [
        tuple(1, 1, 1), tuple(1, 1, 2), tuple(1, 1, 3),
        tuple(1, 2, 2), tuple(1, 2, 3),
        tuple(1, 3, 3),
        tuple(2, 2, 2), tuple(2, 2, 3),
        tuple(2, 3, 3),
        tuple(3, 3, 3),
    ]);
}
