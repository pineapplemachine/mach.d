module mach.range.unique;

private:

import mach.traits : canHash, ElementType, isIterable;

public:



enum validUniqueBy(Iter, alias by) = (
    canHash!(typeof(by(ElementType!Iter.init)))
);

enum canUnique(Iter, alias by = DefaultUniqueBy) = (
    isIterable!Iter && validUniqueBy!(Iter, by)
);

alias DefaultUniqueBy = (element) => (element);



/// Return true when all elements of the iterable are unique, as determined by
/// hashing and equality functions. Return true when the iterable is empty.
/// Evaluates eagerly.
auto unique(alias by = DefaultUniqueBy, Iter)(auto ref Iter iter) if(canUnique!(Iter, by)){
    alias ByType = typeof(by(ElementType!Iter.init));
    alias History = bool[ByType]; // TODO: Proper set?
    History history;
    foreach(element; iter){
        auto byelement = by(element);
        if(byelement in history){
            return false;
        }else{
            history[byelement] = true;
        }
    }
    return true;
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import std.ascii : toLower;
}
unittest{
    tests("Unique", {
        tests("Default by", {
            test("abc".unique);
            test("xyz".unique);
            test("a".unique);
            test("".unique);
            testf("hello".unique);
            testf("aa".unique);
        });
        tests("Custom by", {
            test("abc".unique!toLower);
            test("ABC".unique!toLower);
            testf("Aa".unique!toLower);
        });
    });
}
