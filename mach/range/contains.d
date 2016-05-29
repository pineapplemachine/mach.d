module mach.range.contains;

private:

import mach.range.indexof : indexofrange, canIndexOfRange;
import mach.range.indexof : indexofelement, canIndexOfElement;
import mach.range.indexof : DefaultIndexOfIndex;

public:



enum canContainsRange(Iter, Sub) = (
    canIndexOfRange!(Iter, Sub, DefaultIndexOfIndex)
);
enum canContainsElement(Iter, Sub) = (
    canIndexOfElement!(Iter, Sub, DefaultIndexOfIndex)
);



auto contains(alias pred, Iter, Sub)(Iter iter, Sub sub) if(canContainsRange!(Iter, Sub)){
    return containsrange!(pred, Iter, Sub)(iter, sub);
}

auto contains(Iter, Sub)(Iter iter, Sub sub) if(canContainsRange!(Iter, Sub)){
    return containsrange!(Iter, Sub)(iter, sub);
}

auto contains(alias pred, Iter, Sub)(Iter iter, Sub sub) if(
    !canContainsRange!(Iter, Sub) && canContainsElement!(Iter, Sub)
){
    return containselement!(pred, Iter, Sub)(iter, sub);
}

auto contains(Iter, Sub)(Iter iter, Sub sub) if(
    !canContainsRange!(Iter, Sub) && canContainsElement!(Iter, Sub)
){
    return containselement!(Iter, Sub)(iter, sub);
}

auto containsrange(alias pred, Iter, Sub)(Iter iter, Sub sub) if(canContainsRange!(Iter, Sub)){
    return indexofrange!(pred)(iter, sub) >= 0;
}

auto containsrange(Iter, Sub)(Iter iter, Sub sub) if(canContainsRange!(Iter, Sub)){
    return indexofrange(iter, sub) >= 0;
}

auto containselement(alias pred, Iter, Sub)(Iter iter, Sub sub) if(canContainsElement!(Iter, Sub)){
    return indexofelement!(pred)(iter, sub) >= 0;
}

auto containselement(Iter, Sub)(Iter iter, Sub sub) if(canContainsElement!(Iter, Sub)){
    return indexofelement(iter, sub) >= 0;
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Contains", {
        tests("Ranges", {
            test("hello world".contains(""));
            test("hello world".contains("hello"));
            test("hello world".contains("world"));
            test("hello world".contains("hello world"));
            testf("hello world".contains("yo"));
        });
        tests("Elements", {
            test("hello".contains('h'));
            test("hello".contains('e'));
            test("hello".contains('l'));
            test("hello".contains('o'));
            testf("hello".contains('z'));
        });
    });
}
