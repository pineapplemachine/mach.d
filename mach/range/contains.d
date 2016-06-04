module mach.range.contains;

private:

import mach.range.find : find, DefaultFindIndex, canFindElement, canFindIterable;

public:



alias DefaultContainsPredicate = (a, b) => (a == b);



auto contains(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElement!(pred, Index, Iter, true)){
    return containselement!(pred, Index, Iter)(iter);
}

auto contains(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindElement!(pred, Index, Iter, true)){
    return containsiterable!(pred, Index, Iter, Find)(iter, subject);
}

auto contains(Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(
    canFindElement!((element) => (element == subject), Index, Iter, true) ||
    canFindIterable!(DefaultContainsPredicate, Index, Iter, Find, true)
){
    static if(canFindElement!((element) => (element == subject), Index, Iter, true)){
        return containselement!((element) => (element == subject), Index, Iter)(iter);
    }else{
        return containsiterable!(DefaultContainsPredicate, Index, Iter, Find)(iter, subject);
    }
}



auto containsiterable(
    alias pred = DefaultContainsPredicate, Index = DefaultFindIndex, Iter, Find
)(Iter iter, Find subject) if(
    canFindIterable!(pred, Index, Iter, Find, true)
){
    return find!(pred, Index)(iter, subject).exists;
}

auto containselement(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElement!(pred, Index, Iter, true)){
    return find!(pred, Index)(iter).exists;
}

auto containselement(Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindElement!((element) => (element == subject), Index, Iter, true)){
    return containselement!((element) => (element == subject), Index, Iter)(iter);
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Contains", {
        tests("Element", {
            test("hello".contains('h'));
            test("hello".contains('e'));
            test("hello".contains('l'));
            test("hello".contains('o'));
            testf("hello".contains('z'));
        });
        tests("Iterable", {
            test("hello world".contains("hello"));
            test("hello world".contains("world"));
            test("hello world".contains("hello world"));
            testf("hello world".contains(""));
            testf("hello world".contains("yo"));
        });
    });
}
