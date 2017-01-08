module mach.range.each;

private:

import mach.traits : isFiniteIterable, isFiniteIterableReverse;

/++ Docs

The `each` function eagerly evaluates a function for every element in
an iterable. The function to be applied is passed as a template argument, and
it must accept a single element from the iterable as its input.
Its lazily-evaluated equivalent is `tap`, defined in `mach.range.tap`.

+/

unittest{ /// Example
    string hello = "";
    "hello".each!(e => hello ~= e);
    assert(hello == "hello");
}

/++ Docs

The module also implements an `eachreverse` function, which operates the same
as `each`, except elements are evaluated in reverse order.

+/

unittest{ /// Example
    string greetings = "";
    "sgniteerg".eachreverse!(e => greetings ~= e);
    assert(greetings == "greetings");
}

public:



/// Apply a function to each element of an iterable.
void each(alias func, Iter)(auto ref Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        func(item);
    }
}

/// Apply a function to each element of an iterable, in reverse.
void eachreverse(alias func, Iter)(auto ref Iter iter) if(isFiniteIterableReverse!Iter){
    foreach_reverse(item; iter){
        func(item);
    }
}



version(unittest){
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Each", {
        int[] input = [1, 2, 3, 4, 5];
        // Forward
        int[] output;
        input.each!((i){output ~= i;});
        test(output.equals(input));
        // Reverse
        int[] outputreverse;
        input.eachreverse!((i){outputreverse ~= i;});
        test(outputreverse.equals([5, 4, 3, 2, 1]));
    });
}
