module mach.range.unique;

private:

import mach.traits : canHash, hasNumericLength;
import mach.traits : isIterable, isFiniteIterable, ElementType;
import mach.collect : DenseHashSet;

public:



/// Determine whether a `by` function is valid for some iterable.
template validUniqueBy(T, alias by){
    enum bool validUniqueBy = canHash!(typeof(by((ElementType!T).init)));
}

alias DefaultUniqueBy = (e) => (e);
static assert(validUniqueBy!(int[], DefaultUniqueBy));



template canUnique(T, alias by = DefaultUniqueBy){
    enum bool canUnique = isFiniteIterable!T && validUniqueBy!(T, by);
}



/// Return true when all elements of the iterable are unique, as determined by
/// hashing and equality functions. Return true when the iterable is empty.
/// Evaluates eagerly.
/// When a `by` function is specified, uniqueness of elements is determined by
/// the uniqueness of the result of calling that function for each element.
auto unique(alias by = DefaultUniqueBy, Iter)(auto ref Iter iter) if(
    canUnique!(Iter, by)
){
    alias History = DenseHashSet!(typeof(by(ElementType!Iter.init)));
    History history;
    foreach(element; iter){
        auto byelement = by(element);
        if(history.contains(byelement)){
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
