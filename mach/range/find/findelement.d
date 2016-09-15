module mach.range.find.findelement;

private:

import mach.traits : ElementType, isPredicate;
import mach.range.enumerate : enumerate, canEnumerate;
import mach.range.filter : filter, canFilter;
import mach.range.find.result;
import mach.range.find.templates;

public:



template canFindElementEager(alias pred, Index, Iter, bool forward = true){
    static if(canFindIn!(Iter, forward)){
        enum bool canFindElementEager = (
            validFindIndex!Index &&
            isPredicate!(pred, ElementType!Iter)
        );
    }else{
        enum bool canFindElementEager = false;
    }
}

alias canFindAllElementsEager = canFindElementEager;

alias canFindAllElements = canFindElementEager;

template canFindAllElementsLazy(alias pred, Index, Iter){
    enum bool canFindAllElementsLazy = (
        canFindAllElementsEager!(pred, Index, Iter) &&
        is(typeof((inout int = 0){
            Iter iter = Iter.init;
            auto enumerated = iter.enumerate;
            auto filtered = enumerated.filter!(element => pred(element.value));
        }))
    );
}



/// Find the first element matching a predicate and get both that matching
/// element and the index at which it was encountered.
auto findfirstelement(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, true)){
    alias Element = ElementType!Iter;
    alias Result = FindResultSingular!(Index, Element);
    Index index;
    foreach(element; iter){
        if(pred(element)) return Result(index, element);
        index++;
    }
    return Result(false);
}

/// Find the last element matching a predicate and get both that matching
/// element and the index at which it was encountered.
auto findlastelement(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElementEager!(pred, Index, Iter, false)){
    alias Element = ElementType!Iter;
    alias Result = FindResultSingular!(Index, Element);
    Index index = iter.length;
    foreach_reverse(element; iter){
        index--;
        if(pred(element)) return Result(index, element);
    }
    return Result(false);
}

/// Find all elements matching a predicate and get both those matching elements
/// and the indexes at which they were encountered.
auto findallelements(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindAllElements!(pred, Index, Iter)){
    static if(canFindAllElementsLazy!(pred, Index, Iter)){
        return findallelementslazy!(pred, Index, Iter)(iter);
    }else{
        return findallelementseager!(pred, Index, Iter)(iter);
    }
}

/// ditto
auto findallelementseager(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindAllElementsEager!(pred, Index, Iter)){
    alias Element = ElementType!Iter;
    alias Result = FindResultPlural!(Index, Element);
    Result[] results;
    Index index;
    foreach(element; iter){
        if(pred(element)) results ~= Result(index, element);
        index++;
    }
    return results;
}

/// ditto
auto findallelementslazy(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindAllElementsLazy!(pred, Index, Iter)){
    return iter.enumerate.filter!(element => pred(element.value));
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Find element", {
        alias isdigit = (ch) => (ch >= '0' && ch <= '9');
        alias nomatch = (e) => (false);
        auto input = "a0b1a";
        tests("Given predicate", {
            tests("First", {
                auto result = input.findfirstelement!isdigit;
                test(result.exists);
                testeq(result.index, 1);
                testeq(result.value, '0');
                auto none = input.findfirstelement!nomatch;
                testf(none.exists);
            });
            tests("Last", {
                auto result = input.findlastelement!isdigit;
                test(result.exists);
                testeq(result.index, 3);
                testeq(result.value, '1');
                auto none = input.findlastelement!nomatch;
                testf(none.exists);
            });
            tests("All", {
                tests("Eager", {
                    auto result = input.findallelementseager!isdigit;
                    testeq("Length", result.length, 2);
                    testeq(result[0].index, 1);
                    testeq(result[0].value, '0');
                    testeq(result[1].index, 3);
                    testeq(result[1].value, '1');
                    auto none = input.findallelementseager!nomatch;
                    testeq("Length", none.length, 0);
                });
                tests("Lazy", {
                    auto range = input.findallelementslazy!isdigit;
                    testeq(range.front.index, 1);
                    testeq(range.front.value, '0');
                    range.popFront();
                    testeq(range.front.index, 3);
                    testeq(range.front.value, '1');
                    range.popFront();
                    test(range.empty);
                });
            });
        });
    });
}
