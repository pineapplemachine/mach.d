module mach.range.asarray;

private:

import mach.text : text;
import mach.traits : isArray, isArrayOf, isIterable, isFiniteIterable, ElementType;
import mach.traits : hasNumericLength, LengthType, canCast;

public:



/// Can an array be made from the iterable without providing an explicit length?
enum canMakeArray(Iter) = (
    isArray!Iter || canMakeFiniteLengthArray!Iter
);
/// ditto
enum canMakeArrayOf(Element, Iter) = (
    isArrayOf!(Element, Iter) || canMakeFiniteLengthArrayOf!(Element, Iter)
);

/// Can an array be made from the iterable, deriving length from the iterable itself?
enum canMakeKnownLengthArray(Iter) = (
    canMakeMaxLengthArray!Iter && isFiniteIterable!Iter && hasNumericLength!Iter
);
/// ditto
enum canMakeKnownLengthArrayOf(Element, Iter) = (
    canMakeKnownLengthArray!Iter &&
    canMakeMaxLengthArrayOf!(Element, Iter)
);

/// Can an array of a default maximum length be made from the iterable?
/// Requires that an iterable be definitely finite.
enum canMakeFiniteLengthArray(Iter) = (
    canMakeMaxLengthArray!Iter && isFiniteIterable!Iter
);
/// ditto
enum canMakeFiniteLengthArrayOf(Element, Iter) = (
    canMakeFiniteLengthArray!Iter &&
    canMakeMaxLengthArrayOf!(Element, Iter)
);

/// Can an array of some given maximum length be made from the iterable?
enum canMakeMaxLengthArray(Iter) = (
    isIterable!Iter
);
/// ditto
template canMakeMaxLengthArrayOf(Element, Iter){
    static if(canMakeMaxLengthArray!Iter){
        enum bool canMakeMaxLengthArrayOf = canCast!(ElementType!Iter, Element);
    }else{
        enum bool canMakeMaxLengthArrayOf = false;
    }
};




/// Create an array of up to the first maxlength items from an iterable of
/// unknown length. If enforce is true, an AssertError is raised when the
/// length of the iterable to convert is found to be longer than the given
/// maxlength.
auto asarray(bool enforce = false, Iter)(auto ref Iter iter, size_t maxlength) if(
    canMakeMaxLengthArray!Iter
){
    return asarray!(ElementType!Iter, enforce, Iter)(iter, maxlength);
}
    
// ditto
auto asarray(Element, bool enforce = false, Iter)(auto ref Iter iter, size_t maxlength) if(
    canMakeMaxLengthArrayOf!(Element, Iter)
){
    Element[] array;
    foreach(item; iter){
        if(array.length >= maxlength){
            static if(enforce) assert(false,
                text("Iterable exceeded maximum expected length ", maxlength, ".")
            );
            else break;
        }
        array ~= item;
    }
    return array;
}



/// Create an array from an arbitrary finite iterable.
auto asarray(Iter)(auto ref Iter iter) if(
    canMakeArray!Iter
){
    return asarray!(ElementType!Iter, Iter)(iter);
}

/// ditto
auto asarray(Element, Iter)(auto ref Iter iter) if(
    canMakeArrayOf!(Element, Iter)
){
    static if(isArrayOf!(Element, Iter)){
        return iter;
    }else static if(canMakeKnownLengthArrayOf!(Element, Iter)){
        return asknownlengtharray!(Element, Iter)(iter, cast(size_t) iter.length);
    }else static if(canMakeFiniteLengthArrayOf!(Element, Iter)){
        return asarray!(Element, false, Iter)(iter, size_t.max);
    }else{
        static assert(false); // This shouldn't happen
    }
}



/// Create array from an iterable where exact length is known at runtime.
auto asknownlengtharray(Element, Iter)(auto ref Iter iter, size_t length) if(
    canMakeMaxLengthArrayOf!(Element, Iter)
){
    Element[] array;
    array.reserve(length);
    foreach(item; iter){
        assert(array.length < length,
            text("Iterable is longer than assumed length ", length, ".")
        );
        array ~= item;
    }
    assert(array.length == length,
        text("Iterable is shorter than assumed length ", length, ".")
    );
    return array;
}



/// Create array from an iterable where exact length is known at compile time.
auto asarray(size_t length, Iter)(auto ref Iter iter) if(canMakeArray!(Iter)){
    return asarray!(ElementType!Iter, length, Iter)(iter);
}

/// ditto
auto asarray(Element, size_t length, Iter)(auto ref Iter iter) if(
    canMakeMaxLengthArrayOf!(Element, Iter)
){
    Element[length] array;
    size_t index = 0;
    foreach(item; iter){
        assert(index < array.length,
            text("Iterable is longer than assumed length ", length, ".")
        );
        array[index++] = item;
    }
    assert(index == array.length,
        text("Iterable is shorter than assumed length ", length, ".")
    );
    return array;
}



version(unittest){
    private:
    import mach.test;
    struct KnownLengthTest{
        size_t start;
        size_t length;
        size_t index;
        this(size_t start, size_t length, size_t index = 0){
            this.start = start;
            this.length = length;
            this.index = index;
        }
        @property auto front(){
            return this.start + index;
        }
        void popFront(){
            this.index++;
        }
        @property bool empty(){
            return this.index >= this.length;
        }
    }
    struct InfiniteRangeTest{
        size_t start;
        size_t index;
        this(size_t start, size_t index = 0){
            this.start = start;
            this.index = index;
        }
        @property auto front(){
            return this.start + index;
        }
        void popFront(){
            this.index++;
        }
        enum bool empty = false;
    }
}
unittest{
    tests("As array", {
        // Basic use case
        testeq(KnownLengthTest(0, 4).asarray, [0, 1, 2, 3]);
        // Finite range with max length
        testeq(KnownLengthTest(0, 4).asarray(2), [0, 1]);
        // With ct length
        testeq(KnownLengthTest(0, 4).asarray!4, [0, 1, 2, 3]);
        // With incorrect ct length
        testfail({KnownLengthTest(0, 4).asarray!6;});
        // Infinite range with max length
        testeq(InfiniteRangeTest(0).asarray(4), [0, 1, 2, 3]);
        testfail({InfiniteRangeTest(0).asarray!true(4);});
        // Specify element type
        auto im = KnownLengthTest(0, 4).asarray!(immutable size_t);
        static assert(is(typeof(im[0]) == immutable size_t));
        testeq(im, [0, 1, 2, 3]);
        // Call for array
        auto ints = [1, 2, 3, 4, 5, 6];
        testis(ints.asarray, ints);
    });
}
