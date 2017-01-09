module mach.range.mutate;

private:

import mach.traits : isMutableFrontRange, isMutableBackRange, ElementType;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.traits : isRandomAccessRange;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

/++ Docs

The `mutate` function is similar to `map`, but the values produced by the
transformation function are persisted to the underlying data.

Note that in order to acquire elements in the range, the transformation
function is called and its output returned. The element in the
underlying data is only actually mutated upon popping, however.
The range's `nextfront` and `nextback` methods can be called to acquire
and mutate the front or back elements without calling the transformation
twice, which is what will happen when separately calling `range.front`
and `range.popFront`.

The range produced by `mutate` supports `length` and `remaining` when the input
does, and infiniteness is propagated. It supports bidirectionality and random
access when the input does.
The range cannot be saved or sliced, on the basis that such operations are
likely to produce unsafe behavior by calling the transformation function
for and accordingly mutating an element more than once.

+/

unittest{ /// Example
    import mach.range.consume : consume;
    int[] array = [0, 1, 2, 3];
    array.mutate!(n => n + 1).consume;
    assert(array == [1, 2, 3, 4]);
}

unittest{ /// Example
    int[] array = [5, 6, 7, 8];
    auto range = array.mutate!(n => n * 2);
    // The array is not actually modified when accessing elements.
    assert(range.front == 10);
    assert(array[0] == 5);
    assert(range.back == 16);
    assert(array[$-1] == 8);
    assert(range[1] == 12);
    assert(array[1] == 6);
    // The elements are modified when popping.
    range.popFront();
    assert(array == [10, 6, 7, 8]);
    range.popBack();
    assert(array == [10, 6, 7, 16]);
}

public:



/// Determine if `mutate` can be called with some inputs.
enum canMutate(Iter, alias transform) = (
    validAsRange!(isMutableFrontRange, Iter) &&
    validMutateTransformation!(Iter, transform)
);

/// Determine whether a `MutateRange` can be constructed from some inputs.
enum canMutateRange(Range, alias transform) = (
    isMutableFrontRange!Range &&
    validMutateTransformation!(Range, transform)
);

/// Determine whether a transformation function is valid for an input.
template validMutateTransformation(Iter, alias transform){
    enum bool validMutateTransformation = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        Element result = transform(Element.init);
    }));
}



/// Maps values from the input range to values in an output range using a
/// transformation function, and differs from the map function in that the
/// input range is also modified to contain the new values.
auto mutate(alias transform, Iter)(Iter iter) if(canMutate!(Iter, transform)){
    auto range = iter.asrange;
    return MutateRange!(transform, typeof(range))(range);
}



struct MutateRange(alias transform, Range) if(canMutateRange!(Range, transform)){
    enum bool isBidirectional = isMutableBackRange!Range;
    
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    Range source;
    
    this(Range source){
        this.source = source;
    }
    
    /// Get the front of the range.
    /// Does not actually modify the underlying data.
    @property auto front(){
        return transform(this.source.front);
    }
    /// Pop the front of the range, and modify the underlying data.
    void popFront(){
        this.source.front = transform(this.source.front);
        this.source.popFront();
    }
    /// Get the front of the range and pop it, and only call the
    /// transformation function once.
    auto nextfront(){
        scope(success) this.source.popFront();
        auto result = transform(this.source.front);
        this.source.front = result;
        return result;
    }
    /// ditto
    alias next = nextfront;
    
    static if(isMutableBackRange!Range){
        /// Get the back of the range.
        /// Does not actually modify the underlying data.
        @property auto back(){
            return transform(this.source.back);
        }
        /// Pop the back of the range, and modify the underlying data.
        void popBack(){
            this.source.back = transform(this.source.back);
            this.source.popBack();
        }
        /// Get the back of the range and pop it, and only call the
        /// transformation function once.
        auto nextback(){
            scope(success) this.source.popBack();
            auto result = transform(this.source.back);
            this.source.back = result;
            return result;
        }
    }
    
    static if(isRandomAccessRange!Range){
        /// Get an element at an index.
        /// Does not actually modify the underlying data.
        auto opIndex(in size_t index){
            return transform(this.source[index]);
        }
    }
    
    static if(isMutableRemoveFrontRange!Range){
        /// Remove the front element from the range.
        void removeFront(){
            this.source.removeFront();
            this.mutfront = false;
        }
    }
    static if(isMutableRemoveBackRange!Range){
        /// Remove the back element from the range.
        void removeBack(){
            this.source.removeBack();
            this.mutback = false;
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.consume : consume, consumereverse;
}
unittest{
    // TODO: More tests
    tests("Mutate", {
        int[] array = [0, 1, 2, 3, 4];
        array.mutate!((n) => (n+1)).consume;
        testeq(array, [1, 2, 3, 4, 5]);
        array.mutate!((n) => (n+1)).consumereverse;
        testeq(array, [2, 3, 4, 5, 6]);
    });
}
