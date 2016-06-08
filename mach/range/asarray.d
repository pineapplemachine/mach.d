module mach.range.asarray;

private:

import mach.traits : isArrayOf, isIterable, isFiniteIterable, ElementType;
import mach.traits : hasNumericLength, LengthType, canCast;

public:



alias canMakeArray = isIterable;

enum canMakeArrayOf(Iter, Element) = (
    canMakeArray!Iter &&
    canCast!(ElementType!Iter, Element)
);

enum canMakeKnownLengthArray(Iter) = (
    canMakeArray!Iter &&
    isFiniteIterable!Iter &&
    hasNumericLength!Iter &&
    canCast!(LengthType!Iter, size_t)
);

enum canMakeKnownLengthArrayOf(Iter, Element) = (
    canMakeKnownLengthArray!Iter &&
    canMakeArrayOf!(Iter, Element)
);



/// Create an array of up to the first maxlength items from an iterable of unknown length.
auto asarray(bool enforce = false, Iter)(Iter iter, size_t maxlength) if(canMakeArray!Iter){
    return asarray!(ElementType!Iter, enforce, Iter)(iter, maxlength);
}
    
// ditto
auto asarray(Element, bool enforce = false, Iter)(Iter iter, size_t maxlength) if(canMakeArrayOf!(Iter, Element)){
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

/// Create an array from an arbitrary iterable of known length.
auto asarray(Iter)(Iter iter) if(canMakeKnownLengthArray!Iter){
    return asarray!(ElementType!Iter, Iter)(iter);
}

/// ditto
auto asarray(Element, Iter)(Iter iter) if(
    canMakeKnownLengthArrayOf!(Iter, Element) && !isArrayOf!(Iter, Element)
){
    return asknownlengtharray!(Element, Iter)(iter, cast(size_t) iter.length);
}

/// Return the given array since it is already an array of the desired type.
auto asarray(Element, Array)(Array array) if(isArrayOf!(Array, Element)){
    return array;
}

/// Create array from an iterable where exact length is known at runtime.
auto asknownlengtharray(Element, Iter)(Iter iter, size_t length) if(canMakeArrayOf!(Iter, Element)){
    Element[] array = new Element[length];
    size_t index = 0;
    foreach(item; iter){
        assert(index < array.length, "Iterable is longer than assumed length.");
        array[index++] = item;
    }
    assert(index == array.length, "Iterable is shorter than assumed length.");
    return array;
}

/// Create array from an iterable where exact length is known at compile time.
auto asarray(size_t length, Iter)(Iter iter) if(canMakeArray!(Iter)){
    return asarray!(ElementType!Iter, length, Iter)(iter);
}

/// ditto
auto asarray(Element, size_t length, Iter)(Iter iter) if(canMakeArrayOf!(Iter, Element)){
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
