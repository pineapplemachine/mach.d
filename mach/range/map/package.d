module mach.range.map;

private:

/++ Docs

This package implements the
[map higher-order function](https://en.wikipedia.org/wiki/Map_(higher-order_function))
for input iterables.

The `map` function creates a range for which each element is the result of a
transformation applied to the corresponding elements of the input iterables,
where the transformation function is passed as a template argument.

`map` comes in both singular and plural varieties. Singular `map` represents
the higher-order map function in its common form, where the transformation
operates upon the elements of a single input iterable.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    auto squares = [1, 2, 3, 4].map!(n => n * n);
    assert(squares.equals([1, 4, 9, 16]));
}

/++ Docs

Plural `map` is an expansion upon that singular form, in that it accepts
multiple input iterables which are enumerated simultaneously; their
corresponding elements are passed collectively to a transformation function.

The length of a plural `map` function is equal to the length of its shortest
input. If all of the inputs are infinite, then so is the range produced
by `map`.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    auto intsa = [1, 2, 3, 4];
    auto intsb = [3, 5, 7, 9];
    // The transformation function must accept the same number of
    // elements as there are input iterables, in this case two.
    auto sums = map!((a, b) => a + b)(intsa, intsb);
    // Output is a sequences of sums of elements of the input.
    assert(sums.equals([4, 7, 10, 13]));
}

/++ Docs

This plural `map` operation may be more commonly expressed as a combination of
`zip` and singular `map` functions, for example:
`auto sums = zip(intsa, intsb).map!(tup => tup[0] + tup[1]);`

Notably, the `zip` function implemented in `mach.range.zip` is in fact a
very simple abstraction of the plural `map` function.

+/

unittest{ /// Example
    import mach.types.tuple : tuple;
    // The `zip` function in `mach.range.zip` performs this same operation.
    auto zipped = map!tuple([0, 1, 2], [3, 4, 5]);
    assert(zipped.front == tuple(0, 3));
}

/++ Docs

Neither singular nor plural `map` ranges allow mutation of their elements.

The singular `map` function provides `length` and `remaining` properties when
its input iterable does. The plural `map` function provides these properties
in the case that all inputs either support the corresponding property, or are
of known infinite length.

The singular `map` function supports bidirectionality when its input does.
The plural `map` function supports bidirectionality only when all inputs
are finite, are bidirectional, and have a valid `remaining` property.

Please note that bidirectionality for plural ranges requires a potentially
nontrivial amount of overhead to account for the case where its inputs are
of varying lengths.

+/

unittest{ /// Example
    import mach.meta.varreduce : varmax;
    auto intsa = [1, 2, 3, 4];
    auto intsb = [5, 0, 4, 0, 3, 0];
    auto intsc = [3, 2, 1, 1, 2];
    auto range = map!varmax(intsa, intsb, intsc);
    // Length is that of the shortest input.
    assert(range.length == intsa.length);
    // Greatest of elements [1, 5, 3]
    assert(range.front == 5);
    // Greatest of elements [4, 0, 1]
    assert(range.back == 4);
}

public:

import mach.range.map.combined;
