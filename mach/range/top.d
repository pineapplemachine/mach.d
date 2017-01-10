module mach.range.top;

private:

import mach.types : Rebindable;
import mach.traits : ElementType, isFiniteIterable, isPredicate;

/++ Docs

The `top` and `bottom` functions can be used to find a minimum or maximum
element according to a comparison function. With the default comparison
function, `top` can be used to find a minimum value in an iterable input
and `bottom` used to find the maximum.

Note that the `mach.range.sort` package provides functions for fully or
partially sorting inputs, rather than simply acquiring a minimum or maximum.

+/

unittest{ /// Examples
    assert([1, 2, 3].top == 1);
    assert([1, 2, 3].bottom == 3);
}

unittest{ /// Examples
    auto strings = ["hello", "how", "are", "you?"];
    alias compare = (a, b) => (a.length < b.length);
    assert(strings.top!compare, "how"); // Get the first shortest string.
    assert(strings.bottom!compare, "hello"); // Get the longest string.
}

public:



template canTop(Iter, alias compare){
    static if(isFiniteIterable!Iter){
        enum bool canTop = isPredicate!(
            compare, ElementType!Iter, ElementType!Iter
        );
    }else{
        enum bool canTop = false;
    }
}

alias DefaultTopComparison = (a, b) => (a < b);



/// Given to a comparison function, get the top-most element in an iterable.
/// By default, the top-most element is defined as the minimum.
auto top(alias compare = DefaultTopComparison, Iter)(
    auto ref Iter iter
) if(canTop!(Iter, compare)){
    alias Element = ElementType!Iter;
    bool first = true;
    Rebindable!Element top;
    foreach(element; iter){
        if(first || compare(element, top)){
            top = element;
            first = false;
        }
    }
    return cast(Element) top;
}

/// Given to a comparison function, get the bottom-most element in an iterable.
/// By default, the bottom-most element is defined as the maximum.
auto bottom(alias compare = DefaultTopComparison, Iter)(
    auto ref Iter iter
) if(canTop!(Iter, compare)){
    return top!((a, b) => (!compare(a, b)))(iter);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Top and bottom", {
        tests("Mutable elements", {
            auto input = [3, 2, 4, 1, 5];
            testeq(input.top, 1);
            testeq(input.bottom, 5);
        });
        tests("Immutable elements", {
            const(const(int)[]) input = [0, 1, 2, 3];
            testeq(input.top, 0);
            testeq(input.bottom, 3);
        });
        tests("Sort stability", {
            auto input = ["a", "ab", "b", "bc"];
            alias comp = (a, b) => (a.length < b.length);
            testeq(input.top, "a");
            testeq(input.bottom, "bc");
        });
    });
}
