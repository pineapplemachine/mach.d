module mach.range.unique;

private:

import mach.traits : canHash, ElementType, isIterable, hasNumericLength;
import mach.collect : DenseHashSet;

public:



/// Determine whether a `by` function is valid for some iterable.
enum validUniqueBy(Iter, alias by) = (
    canHash!(typeof(by(ElementType!Iter.init)))
);

/// Determine whether it's possible to call unique given an iterable type and a
/// `by` function.
enum canUnique(Iter, alias by = DefaultUniqueBy) = (
    isIterable!Iter && validUniqueBy!(Iter, by)
);

/// The default `by` function.
alias DefaultUniqueBy = (element) => (element);



/// Default for makehistory argument of unique function. Given an iterable and
/// a `by` function, any function passed for that argument should return an
/// object supporting both `history.add(element)` and `element in history`
/// syntax, such as a set.
auto DefaultUniqueMakeHistory(alias by, Iter)(auto ref Iter iter){
    alias ByType = typeof(by(ElementType!Iter.init));
    enum hasLength = hasNumericLength!Iter;
    DenseHashSet!(ByType, !hasLength) history;
    static if(hasLength) history.reserve(iter.length * 4);
    return history;
}



/// Return true when all elements of the iterable are unique, as determined by
/// hashing and equality functions. Return true when the iterable is empty.
/// Evaluates eagerly.
/// When a `by` function is specified, uniqueness of elements is determined by
/// the uniqueness of the result of calling that function for each element.
auto unique(alias by = DefaultUniqueBy, alias makehistory = DefaultUniqueMakeHistory, Iter)(
    auto ref Iter iter
) if(canUnique!(Iter, by)){
    
    auto history = makehistory!by(iter);
    foreach(element; iter){
        auto byelement = by(element);
        if(byelement in history){
            return false;
        }else{
            history.add(byelement);
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
