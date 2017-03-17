module mach.range.asarray;

private:

import mach.text : text;
import mach.types : KeyValuePair;
import mach.traits : isArray, isArrayOf, isIterable, isFiniteIterable, ElementType;
import mach.traits : hasNumericLength, hasNumericRemaining, canCast;
import mach.traits : isAssociativeArray, ArrayKeyType, ArrayValueType;

private template canGetAsArrayLength(T){
    enum bool canGetAsArrayLength = hasNumericRemaining!T || hasNumericLength!T;
}

private size_t getasarraylength(T)(auto ref T input){
    static if(hasNumericRemaining!T){
        return cast(size_t) input.remaining;
    }else static if(hasNumericLength!T){
        return cast(size_t) input.length;
    }else{
        static assert(false); // Shouldn't happen
    }
}

/++ Docs

The `asarray` function can be applied to an iterable to produce a fully
in-memory array of its contents.

When the input is known to be finite, the function can be evaluated with the
iterable as the only argument.

Note that when the input is itself an array, the function returns `array.dup`.

+/

unittest{ /// Example
    import mach.range.filter : filter;
    auto range = [0, 1, 2, 3].filter!(n => n % 2);
    auto array = range.asarray;
    assert(array == [1, 3]);
}

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto array = rangeof(0, 1, 2, 3).asarray;
    assert(array == [0, 1, 2, 3]);
}

/++ Docs

For known finite inputs, the `asarray` function can receive an optional
argument indicating maximum length;
any elements in the input past that length will be excluded from the array.
For infinite inputs, the maximum length argument is mandatory.

When the input is itself an array, the function returns `slice.dup` where
`slice` is the first so many elements of the array, as determined by the
specified maximum length.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto array = rangeof(0, 1, 2, 3).asarray(2);
    assert(array == [0, 1]);
}

unittest{ /// Example
    import mach.range.repeat : repeat;
    auto range = [0, 1, 2].repeat; // Repeat infinitely
    auto array = range.asarray(5);
    testeq(array, [0, 1, 2, 0, 1]);
}

unittest{ /// Example
    import mach.range.repeat : repeat;
    auto range = [0, 1, 2].repeat; // Repeat infinitely
    static assert(!is(typeof(
        range.asarray // Fails because a maximum length is not provided.
    )));
}

/++ Docs

The `asarray` function is also implemented for associative arrays.
The constructed array is a sequence of key, value pairs represented
by the `KeyValuePair` type defined in `mach.types.keyvaluepair`.

+/

unittest{ /// Example
    auto array = ["hello": "world"].asarray;
    assert(array.length == 1);
    assert(array[0].key == "hello");
    assert(array[0].value == "world");
}

public:



/// Can an array be made from the iterable without providing an explicit length?
enum canMakeArray(Iter) = (
    !isAssociativeArray!Iter && (
        isArray!Iter || canMakeFiniteLengthArray!Iter
    )
);
/// ditto
enum canMakeArrayOf(Element, Iter) = (
    isArrayOf!(Element, Iter) || canMakeFiniteLengthArrayOf!(Element, Iter)
);

/// Can an array be made from the iterable, deriving length from the iterable itself?
enum canMakeKnownLengthArray(Iter) = (
    canMakeMaxLengthArray!Iter && isFiniteIterable!Iter && canGetAsArrayLength!Iter
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
    static if(isArrayOf!(Element, Iter)){
        return iter[0 .. maxlength < iter.length ? maxlength : iter.length].dup;
    }else{
        Element[] array;
        foreach(item; iter){
            if(array.length >= maxlength){
                static if(enforce) assert(false,
                    text("Iterable exceeded maximum expected length ", maxlength, ".")
                );
                else break;
            }
            array ~= cast(Element) item;
        }
        return array;
    }
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
        return iter.dup;
    }else static if(canMakeKnownLengthArrayOf!(Element, Iter)){
        return asknownlengtharray!(Element, Iter)(
            iter, cast(size_t) getasarraylength(iter)
        );
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
        array ~= cast(Element) item;
    }
    assert(array.length == length,
        text("Iterable is shorter than assumed length ", length, ".")
    );
    return array;
}



/// Create an array of key, value pairs from an associative array.
auto asarray(T)(auto ref T input) if(isAssociativeArray!T){
    alias Pair = KeyValuePair!(ArrayKeyType!T, ArrayValueType!T);
    Pair[] array;
    array.reserve(input.length);
    foreach(key, value; input){
        array ~= Pair(key, value);
    }
    return array;
}



version(unittest){
    private:
    import mach.test;
    struct KnownLengthTest{
        int low, high;
        int index = 0;
        @property bool empty() const{return this.index >= this.length;}
        @property size_t length() const{return this.high - this.low;}
        @property size_t remaining() const{return this.length - this.index;}
        @property int front() const{return this.low + this.index;}
        void popFront(){this.index++;}
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
        tests("Automatic length", {
            testeq(KnownLengthTest(0, 4).asarray, [0, 1, 2, 3]);
        });
        tests("Finite range, max length", {
            testeq(KnownLengthTest(0, 4).asarray(2), [0, 1]);
        });
        tests("Infinite range, max length", {
            testeq(InfiniteRangeTest(0).asarray(4), [0, 1, 2, 3]);
            testfail({InfiniteRangeTest(0).asarray!true(4);});
        });
        tests("Specify element type", {
            auto im = KnownLengthTest(0, 4).asarray!(immutable size_t);
            static assert(is(typeof(im[0]) == immutable size_t));
            testeq(im, [0, 1, 2, 3]);
        });
        tests("Partially-consumed range", {
            auto range = KnownLengthTest(0, 6);
            range.popFront();
            testeq(range.asarray, [1, 2, 3, 4, 5]);
        });
        tests("Array as array", {
            // Implicit length
            auto ints = [1, 2, 3, 4, 5, 6];
            testisnot(ints.asarray, ints);
            // Explicit length
            auto as = ints.asarray(3);
            ints[0] = 10;
            testeq(as[0], 1);
        });
        tests("Associative array", {
            auto array = asarray(["a": "aardvark", "b": "bear", "c": "crow"]);
            testeq(array.length, 3);
            foreach(pair; array){
                testeq(pair.key[0], pair.value[0]);
            }
        });
    });
}
