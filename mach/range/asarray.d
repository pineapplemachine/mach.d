module mach.range.asarray;

private:

import std.traits : isArray;
import mach.traits : isArrayOf, isIterable, isFiniteIterable, ElementType;
import mach.traits : hasNumericLength, LengthType, canCast;

public:



/// Can an array be made from the iterable without providing an explicit length?
enum canMakeArray(Iter) = (
    isArray!Iter || canMakeFiniteLengthArray!Iter
);
/// ditto
enum canMakeArrayOf(Iter, Element) = (
    isArrayOf!(Iter, Element) || canMakeFiniteLengthArrayOf!(Iter, Element)
);

/// Can an array be made from the iterable, deriving length from the iterable itself?
enum canMakeKnownLengthArray(Iter) = (
    canMakeMaxLengthArray!Iter && isFiniteIterable!Iter && hasNumericLength!Iter
);
/// ditto
enum canMakeKnownLengthArrayOf(Iter, Element) = (
    canMakeKnownLengthArray!Iter &&
    canMakeMaxLengthArrayOf!(Iter, Element)
);

/// Can an array of a default maximum length be made from the iterable?
/// Requires that an iterable be definitely finite.
enum canMakeFiniteLengthArray(Iter) = (
    canMakeMaxLengthArray!Iter && isFiniteIterable!Iter
);
/// ditto
enum canMakeFiniteLengthArrayOf(Iter, Element) = (
    canMakeFiniteLengthArray!Iter &&
    canMakeMaxLengthArrayOf!(Iter, Element)
);

/// Can an array of some given maximum length be made from the iterable?
enum canMakeMaxLengthArray(Iter) = (
    isIterable!Iter
);
/// ditto
template canMakeMaxLengthArrayOf(Iter, Element){
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
    canMakeMaxLengthArrayOf!(Iter, Element)
){
    Element[] array;
    foreach(item; iter){
        if(array.length >= maxlength){
            static if(enforce) assert(false, "Iterable exceeded maximum array length.");
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
    canMakeArrayOf!(Iter, Element)
){
    static if(isArrayOf!(Iter, Element)){
        return iter;
    }else static if(canMakeKnownLengthArrayOf!(Iter, Element)){
        return asknownlengtharray!(Element, Iter)(iter, cast(size_t) iter.length);
    }else static if(canMakeDefaultLengthArrayOf!(Iter, Element)){
        return asarray!(Element, Iter)(iter, size_t.max);
    }else{
        assert(false); // This shouldn't happen
    }
}



/// Create array from an iterable where exact length is known at runtime.
auto asknownlengtharray(Element, Iter)(auto ref Iter iter, size_t length) if(
    canMakeMaxLengthArrayOf!(Iter, Element)
){
    Element[] array;
    array.reserve(length);
    foreach(item; iter){
        assert(array.length < length, "Iterable is longer than assumed length.");
        array ~= item;
    }
    assert(array.length == length, "Iterable is shorter than assumed length.");
    return array;
}



/// Create array from an iterable where exact length is known at compile time.
auto asarray(size_t length, Iter)(auto ref Iter iter) if(canMakeArray!(Iter)){
    return asarray!(ElementType!Iter, length, Iter)(iter);
}

/// ditto
auto asarray(Element, size_t length, Iter)(auto ref Iter iter) if(
    canMakeMaxLengthArrayOf!(Iter, Element)
){
    Element[length] array;
    size_t index = 0;
    foreach(item; iter){
        assert(index < array.length, "Iterable is longer than assumed length.");
        array[index++] = item;
    }
    assert(index == array.length, "Iterable is shorter than assumed length.");
    return array;
}



version(unittest){
    private:
    import mach.error.unit;
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
        testeq("Most common use case",
            KnownLengthTest(0, 4).asarray, [0, 1, 2, 3]
        );
        testeq("Max length",
            KnownLengthTest(0, 4).asarray(2), [0, 1]
        );
        testeq("Length known at compile time",
            KnownLengthTest(0, 4).asarray!4, [0, 1, 2, 3]
        );
        fail("Incorrect known length", {
            KnownLengthTest(0, 4).asarray!6;
        });
        tests("Max length of infinite range", {
            testeq(InfiniteRangeTest(0).asarray(4), [0, 1, 2, 3]);
            fail({InfiniteRangeTest(0).asarray!true(4);});
        });
        auto ints = [1, 2, 3, 4, 5, 6];
        testis("Calling asarray on an array",
            ints.asarray, ints
        );
    });
}
