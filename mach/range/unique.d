module mach.range.unique;

private:

import mach.traits : canHash, hasNumericLength;
import mach.traits : isIterable, isFiniteIterable, ElementType;
import mach.collect : DenseHashSet;

public:



/// Determine whether a `by` function is valid for some iterable.
enum validUniqueBy(Iter, alias by) = (
    canHash!(typeof(by(ElementType!Iter.init)))
);

/// Determine whether a `makehistory` function is valid for some iterable.
template validUniqueMakeHistory(Iter, alias by, alias makehistory){
    static if(isIterable!Iter){
        alias ByType = typeof(by(ElementType!Iter.init));
        enum bool validUniqueMakeHistory = is(typeof({
            auto history = makehistory!by(Iter.init);
            history.add(ByType.init);
            if(ByType.init in history) return;
        }));
    }else{
        enum bool validUniqueMakeHistory = false;
    }
}

/// Determine whether it's possible to call unique with the given input types.
enum canUnique(
    Iter, alias by = DefaultUniqueBy,
    alias makehistory = DefaultUniqueMakeHistory
) = (
    isFiniteIterable!Iter && validUniqueBy!(Iter, by) &&
    validUniqueMakeHistory!(Iter, by, makehistory)
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
) if(canUnique!(Iter, by, makehistory)){
    
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
    import mach.test;
    import mach.range.compare : equals;
    auto tolower(in char ch){
        if(ch >= 'A' && ch <= 'Z') return ch - ('A' - 'a');
        else return ch;
    }
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
            test("abc".unique!tolower);
            test("ABC".unique!tolower);
            testf("Aa".unique!tolower);
        });
    });
}
