module mach.range.flatten;

private:

import mach.traits : isIterable, ElementType;
import mach.range.chain : chainiter, canChainIterableOfIterables;
import mach.range.map : map;

/++ Docs

Where an iterable is an iterable of iterables, the `flatten` function
sequentially enumerates the elements of each iterable within that input
iterable, down to the lowest level of nesting. When the input is an iterable
whose elements are not themselves iterables, `flatten` simply returns its input.

The effect of this is that the elements of an output produced by `flatten` will
never be iterables.

Except for the case where `flatten` returns its input, the function returns
a range, lazily enumerating the flattened contents.

+/

unittest{ /// Example
    // Flatten an array of arrays of ints, producing a sequence of ints.
    import mach.range.compare : equals;
    int[][] array = [[0, 1, 2], [3], [4, 5]];
    assert(array.flatten.equals([0, 1, 2, 3, 4, 5]));
}

unittest{ /// Example
    // Flatten an array of strings, producing a string.
    import mach.range.compare : equals;
    assert(["hello", " ", "world"].flatten.equals("hello world"));
}

unittest{ /// Example
    // Flatten an array of arrays of arrays of ints, producing a sequence of ints.
    import mach.range.compare : equals;
    int[][][] array = [[[0, 1], [2]], [[3], [], [4, 5]]];
    assert(array.flatten.equals([0, 1, 2, 3, 4, 5]));
}

unittest{
    // Flatten an already-flat array of ints, producing the same array of ints.
    assert([0, 1, 2, 3].flatten == [0, 1, 2, 3]);
}

public:



/// Given an iterable of iterables (possibly of iterables (possibly of iterables))
/// construct a range that iterates only through the atomic elements of each.
auto flatten(Iter)(auto ref Iter iter) if(isIterable!Iter){
    static if(canChainIterableOfIterables!Iter){
        static if(canChainIterableOfIterables!(ElementType!Iter)){
            return flatten(iter.map!(e => e.flatten));
        }else{
            return chainiter(iter);
        }
    }else{
        return iter;
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Flatten", {
        tests("Already flat", {
            int[] empty;
            test!equals(empty.flatten, new int[0]);
            test!equals([0].flatten, [0]);
            test!equals([0, 1, 2].flatten, [0, 1, 2]);
        });
        tests("Nested arrays", {
            int[][] empty;
            test!equals(empty.flatten, new int[0]);
            test!equals([[0], []].flatten, [0]);
            test!equals([[1, 2], [3, 4]].flatten, [1, 2, 3, 4]);
        });
        tests("Twice-nested", {
            int[][][] empty;
            test!equals(empty.flatten, new int[0]);
            test!equals([[[], [0]], [[], [1]]].flatten, [0, 1]);
            test!equals(
                [[[1, 2], [3, 4]], [[5, 6], [7, 8]]].flatten,
                [1, 2, 3, 4, 5, 6, 7, 8]
            );
        });
    });
}
