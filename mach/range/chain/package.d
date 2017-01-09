module mach.range.chain;

private:

/++ Docs

The `chain` function serves two similar but differing purposes.
It accepts a sequence of iterables as arguments, producing a range which
enumerates the elements of the inputs in sequence.
Or it accepts an iterable of iterables, producing a range which
enumerates the elements of the input's own elements in sequence.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    // Chain several iterables
    assert(chain("hello", " ", "world").equals("hello world"));
    // Chain an iterable of iterables
    assert(["hello", " ", "world"].chain.equals("hello world"));
}

/++ Docs

Though the `chain` function should in almost all cases be able to discern
intention, the package provides `chainiter` and `chainiters` functions when
it becomes necessary to explicitly specify which form of chaining is desired.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    assert(chainiters("hello", " ", "world").equals("hello world"));
}

unittest{ /// Example
    import mach.range.compare : equals;
    assert(chainiter(["hello", " ", "world"]).equals("hello world"));
}

public:

import mach.range.chain.singular;
import mach.range.chain.plural;
import mach.range.chain.simple;
