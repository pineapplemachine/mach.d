module mach.range.indexof;

private:

import mach.range.find : find, canFindElementEager, canFindIterable;

public:



alias DefaultIndexOfIndex = ptrdiff_t;

alias DefaultIndexOfPredicate = (a, b) => (a == b);



auto indexof(alias pred, Index = DefaultIndexOfIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, true)){
    return indexofelement!(pred, Index, Iter)(iter);
}

auto indexof(alias pred, Index = DefaultIndexOfIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindElementEager!(pred, Index, Iter, true)){
    return indexofiter!(pred, Index, Iter, Find)(iter, subject);
}

auto indexof(Index = DefaultIndexOfIndex, Iter, Find)(
    Iter iter, Find subject
) if(
    canFindElementEager!((element) => (element == subject), Index, Iter, true) ||
    canFindIterable!(DefaultIndexOfPredicate, Index, Iter, Find, true)
){
    static if(canFindElementEager!((element) => (element == subject), Index, Iter, true)){
        return indexofelement!((element) => (element == subject), Index, Iter)(iter);
    }else{
        return indexofiter!(DefaultIndexOfPredicate, Index, Iter, Find)(iter, subject);
    }
}



auto indexofiter(
    alias pred = DefaultIndexOfPredicate, Index = DefaultIndexOfIndex, Iter, Find
)(Iter iter, Find subject) if(
    canFindIterable!(pred, Index, Iter, Find, true)
){
    auto result = find!(pred, Index)(iter, subject);
    return result.exists ? result.index : -1;
}

auto indexofelement(alias pred, Index = DefaultIndexOfIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, true)){
    auto result = find!(pred, Index)(iter);
    return result.exists ? result.index : -1;
}

auto indexofelement(Index = DefaultIndexOfIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindElementEager!((element) => (element == subject), Index, Iter, true)){
    return indexofelement!((element) => (element == subject), Index, Iter)(iter);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Index of", {
        tests("Element", {
            testeq("hello".indexof('h'), 0);
            testeq("hello".indexof('e'), 1);
            testeq("hello".indexof('l'), 2);
            testeq("hello".indexof('o'), 4);
            testeq("hello".indexof('z'), -1);
        });
        tests("Iterable", {
            tests("Single length subs", {
                testeq("hello".indexof("h"), 0);
                testeq("hello".indexof("e"), 1);
                testeq("hello".indexof("l"), 2);
                testeq("hello".indexof("o"), 4);
                testeq("hello".indexof("z"), -1);
            });
            tests("Greater-than-one length subs", {
                testeq("hello".indexof("he"), 0);
                testeq("hello".indexof("hel"), 0);
                testeq("hello".indexof("hell"), 0);
                testeq("hello".indexof("hello"), 0);
                testeq("hello".indexof("llo"), 2);
                testeq("hello".indexof("lo"), 3);
            });
            tests("Zero length sub", {
                testeq("hello".indexof(""), -1);
            });
            tests("Tricky", {
                testeq("xyzaxyzaxyzb".indexof("xyzaxyzb"), 4);
            });
        });
    });
}
