module mach.range.contains;

private:

import mach.range.find : find, DefaultFindIndex, canFindElementEager, canFindIterable;

/++ Docs

This module implements a `contains` function capable of searching an input
iterable for an element satisfying a predicate, for an element equal to an
input, or for a substring.

+/

unittest{ /// Example
    // Search for an equivalent element.
    assert("hello".contains('h'));
    assert(!"hello".contains('x'));
}

unittest{ /// Example
    // Search for an element satisfying a predicate.
    import mach.text.ascii : isupper;
    assert("upper CASE".contains!isupper);
    assert(!"lower case".contains!isupper);
}

unittest{ /// Example
    // Search for a substring.
    assert("hello world".contains("hello"));
    assert("hello world".contains("world"));
    assert(!"hello world".contains("nope"));
}

unittest{ /// Example
    // Search for a case-insensitive substring.
    import mach.text.ascii : tolower;
    alias compare = (a, b) => (a.tolower == b.tolower);
    assert("Hello World".contains!compare("HELLO"));
    assert(!"Hello World".contains!compare("Nope"));
}

public:



alias DefaultContainsPredicate = (a, b) => (a == b);



auto contains(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, true)){
    return containselement!(pred, Index, Iter)(iter);
}

auto contains(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindIterable!(pred, Index, Iter, Find, true)){
    return containsiter!(pred, Index, Iter, Find)(iter, subject);
}

auto contains(Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(
    canFindElementEager!((element) => (element == subject), Index, Iter, true) ||
    canFindIterable!(DefaultContainsPredicate, Index, Iter, Find, true)
){
    static if(canFindElementEager!((element) => (element == subject), Index, Iter, true)){
        return containselement!((element) => (element == subject), Index, Iter)(iter);
    }else{
        return containsiter!(DefaultContainsPredicate, Index, Iter, Find)(iter, subject);
    }
}



auto containsiter(
    alias pred = DefaultContainsPredicate, Index = DefaultFindIndex, Iter, Find
)(Iter iter, Find subject) if(
    canFindIterable!(pred, Index, Iter, Find, true)
){
    return find!(pred, Index)(iter, subject).exists;
}

auto containselement(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, true)){
    return find!(pred, Index)(iter).exists;
}

auto containselement(Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindElementEager!((element) => (element == subject), Index, Iter, true)){
    return containselement!((element) => (element == subject), Index, Iter)(iter);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Contains", {
        tests("Element", {
            tests("Implicit predicate", {
                test("hello".contains('h'));
                test("hello".contains('e'));
                test("hello".contains('l'));
                test("hello".contains('o'));
                testf("hello".contains('z'));
            });
            tests("Explicit predicate", {
                test("hello".contains!(ch => ch == 'l'));
                testf("hello".contains!(ch => ch == 'x'));
            });
        });
        tests("Iterable", {
            tests("Implicit predicate", {
                test("hello world".contains("hello"));
                test("hello world".contains("world"));
                test("hello world".contains("hello world"));
                testf("hello world".contains(""));
                testf("hello world".contains("yo"));
            });
            tests("Explicit predicate", {
                alias comp = (a, b) => (a == b - 1);
                test([0, 1, 2].contains!comp([2, 3]));
                testf([0, 1, 2].contains!comp([5]));
            });
        });
    });
}
