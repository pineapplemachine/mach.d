module mach.math.median;

private:

import mach.traits : Unqual, ElementType, isFiniteIterable, isNumeric;
import mach.range.sort : copyinsertionsort;
import mach.math.mean : mean;

/++ Docs

The `median` function calculates the [median](https://en.wikipedia.org/wiki/Median)
of the values in an input iterable. The input must be finite and not empty.
If the input is empty, then in release mode `median` will throw a
`MedianEmptyInputError`.
(When not compiling in release mode, the check necessary to report the error
is omitted.)

+/

unittest{ /// Example
    assert([1, 2, 3, 4, 5].median == 3);
    assert([5, 2, 4, 1].median == 3);
}

unittest{ /// Example
    import mach.error.mustthrow : mustthrow;
    mustthrow!MedianEmptyInputError({
        new int[0].median; // Can't calculate median with an empty input!
    });
}

public:



/// Error thrown when the input to `median` was an empty iterable.
class MedianEmptyInputError: Error{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Cannot determine median of an empty sequence of values.", file, line, null);
    }
}



/// Determine whether it is possible to get the median given an iterable of values.
template canGetMedian(T){
    static if(isFiniteIterable!T){
        enum bool canGetMedian = isNumeric!(ElementType!T);
    }else{
        enum bool canGetMedian = false;
    }
}



/// Calculate the median of some input iterable.
/// Does not modify the input.
/// Throws a `MedianEmptyInputError` when the input was empty,
/// except in release mode where the check is omitted.
/// TODO: Provide a more optimized implementation for when the input may
/// itself be modified.
auto median(T)(auto ref T values) if(canGetMedian!T){
    auto sorted = values.copyinsertionsort;
    version(assert){
        static const error = new MedianEmptyInputError();
        if(sorted.length == 0) throw error;
    }
    if(sorted.length % 2){
        return sorted[sorted.length / 2];
    }else{
        return mean(sorted[sorted.length / 2], sorted[sorted.length / 2 - 1]);
    }
}



private version(unittest){
    import mach.error.mustthrow : mustthrow;
}
unittest{
    mustthrow!MedianEmptyInputError({
        new int[0].median;
    });
}
unittest{
    assert([0].median == 0);
    assert([0, 2].median == 1);
    assert([0, 1].median == 0);
    assert([0.0, 1.0].median == 0.5);
    assert([1, 2, 3].median == 2);
    assert([2, 3, 1].median == 2);
    assert([-100, 1, 3, 4].median == 2);
    assert([int.min, 11, int.max].median == 11);
}
