module mach.range.zip;

private:

import mach.types : tuple;
import mach.meta : varmap;
import mach.range.asrange : asrange;
import mach.range.map.plural : mapplural, canMapPlural;

/++ Docs

The `zip` function accepts any number of input iterables as variadic arguments
and from them produces a range of tuples, where each tuple represents the
corresponding elements in those iterables.

The length of a range returned by `zip` is equal to the length of its shortest
input.

`zip` is a very simple abstraction of the plural `map` function defined
in `mach.range.map`; see its documentation for more detailed information
regarding the range that is returned.

+/

unittest{ /// Example
    import mach.types : tuple;
    auto range = zip("apple", "bear", "car", "dumpling");
    assert(range.front == tuple('a', 'b', 'c', 'd'));
    assert(range.length == 3); // Length is that of the shortest input, "car".
}

unittest{ /// Example
    auto range = zip([0, 1, 2, 3], [0, 2, 4, 6]);
    foreach(first, second; range){
        assert(first * 2 == second);
    }
}

public:



/// Determine whether some types are valid input for the `zip` function.
enum canZip(T...) = canMapPlural!(tuple, T);

/// An abstraction upon the plural `map` function which enumerates tuples
/// built from the elements of its inputs.
auto zip(Iters...)(auto ref Iters iters) if(canZip!Iters){
    return mapplural!tuple(varmap!(e => e.asrange)(iters).expand);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Zip", {
        auto inputa = ['h', 'a', 'y'];
        auto inputb = ['o', 'r', 'o'];
        auto inputc = ['w', 'e', 'u'];
        auto range = zip(inputa, inputb, inputc);
        testeq(range[0], tuple('h', 'o', 'w'));
        testeq(range[1], tuple('a', 'r', 'e'));
        testeq(range[2], tuple('y', 'o', 'u'));
    });
}
