module mach.range.join;

private:

import mach.range.intersperse : intersperse, canIntersperse;
import mach.range.chain : chainiter, canChainIterableOfIterables;
import mach.range.asrange : validAsRange;

public:



template canJoin(Iter){
    enum bool canJoin = canChainIterableOfIterables!(Iter);
}

template canJoin(Iter, Sep){
    enum bool canJoin = canIntersperse!(Iter, Sep, size_t);
}



/// Archetypical string join operation. ["abc", "def"].join(", ") == "abc, def"
auto join(bool frontsep = false, bool backsep = false, Iter, Sep)(
    auto ref Iter iter, auto ref Sep separator
) if(canJoin!(Iter, Sep)){
    return chainiter(intersperse!(frontsep, backsep)(iter, separator, size_t(2)));
}

/// Special case intended to allow joining an array of strings using a character.
/// TODO: Abstract this (Probably easier said than done)
auto join(bool frontsep = false, bool backsep = false, T)(T[][] strings, T ch){
    return join!(frontsep, backsep)(strings, [ch]);
}

/// In the absence of a separator just chain the input iterator. (Because why not?)
auto join(Iter)(auto ref Iter iter) if(canJoin!Iter){
    return chainiter(iter);
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Join", {
        test(["abc", "def", "ghi"].join(", ").equals("abc, def, ghi"));
        test(["abc", "def", "ghi"].join("").equals("abcdefghi"));
        test(["abc", "def", "ghi"].join.equals("abcdefghi"));
        test(["abc", "def", "ghi"].join(',').equals("abc,def,ghi"));
        test(["a", "b"].join!(false, true)('.').equals("a.b."));
        test(["a", "b"].join!(true, false)('.').equals(".a.b"));
        test(["a", "b"].join!(true, true)('.').equals(".a.b."));
        test(["abc"].join(", ").equals("abc"));
        test(["abc"].join("").equals("abc"));
        test((new string[0]).join(", ").equals(""));
        test((new string[0]).join("").equals(""));
    });
}
