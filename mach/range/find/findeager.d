module mach.range.find.findeager;

private:

import std.traits : isIntegral;
import mach.traits : isIterable, isIterableReverse, ElementType, isPredicate;
import mach.traits : isRange, isSavingRange, isBidirectionalRange;
import mach.traits : hasNumericIndex, hasNumericLength;
import mach.range.asrange : asrange, validAsSavingRange, validAsBidirectionalRange;

import mach.range.find.result;
import mach.range.find.templates;
import mach.range.find.threads;

public:



private template findwrapper(
    string name, bool forward = true,
    alias findelement, alias findrandomaccess, alias findsaving
){
    auto findwrapperfunc(alias pred, Index = DefaultFindIndex, Iter)(
        Iter iter
    ) if(canFindElement!(pred, Index, Iter, forward)){
        return findelement!(pred, Index, Iter)(iter);
    }
    
    auto findwrapperfunc(alias pred, Index = DefaultFindIndex, Iter, Find)(
        Iter iter, Find subject
    ) if(canFindIterable!(pred, Index, Iter, Find, forward)){
        static if(canFindRandomAccess!(pred, Index, Iter, Find, forward)){
            return findrandomaccess!(pred, Index, Iter, Find)(iter, subject);
        }else{
            return findsaving!(pred, Index, Iter, Find)(iter, subject);
        }
    }
    
    auto findwrapperfunc(Index = DefaultFindIndex, Iter, Find)(
        Iter iter, Find subject
    ) if(
        canFindElement!((element) => (element == subject), Index, Iter, forward) ||
        canFindIterable!(DefaultFindPredicate, Index, Iter, Find, forward)
    ){
        alias DefaultFindElementPredicate = (element) => (element == subject);
        static if(canFindElement!(DefaultFindElementPredicate, Index, Iter, forward)){
            return findelement!(DefaultFindElementPredicate, Index, Iter)(iter);
        }else static if(canFindRandomAccess!(DefaultFindPredicate, Index, Iter, Find, forward)){
            return findrandomaccess!(DefaultFindPredicate, Index, Iter, Find)(iter, subject);
        }else{
            return findsaving!(DefaultFindPredicate, Index, Iter, Find)(iter, subject);
        }
    }
    
    mixin(`alias ` ~ name ~ ` = findwrapperfunc;`);
}



mixin findwrapper!(
    `findfirst`, true, findfirstelement, findfirstrandomaccess, findfirstsaving
);

mixin findwrapper!(
    `findlast`, false, findlastelement, findlastrandomaccess, findlastsaving
);

mixin findwrapper!(
    `findall`, true, findallelements, findallrandomaccess, findallsaving
);

alias find = findfirst;



/// Find the first element matching a predicate and get both that matching
/// element and the index at which it was encountered.
auto findfirstelement(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElement!(pred, Index, Iter, true)){
    alias Element = ElementType!Iter;
    Index index;
    foreach(element; iter){
        if(pred(element)){
            return FindResult!(Index, Element)(index, element);
        }
        index++;
    }
    return FindResult!(Index, Element)(false);
}

/// Find the last element matching a predicate and get both that matching
/// element and the index at which it was encountered.
auto findlastelement(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElement!(pred, Index, Iter, false)){
    alias Element = ElementType!Iter;
    Index index = iter.length;;
    foreach_reverse(element; iter){
        index--;
        if(pred(element)){
            return FindResult!(Index, Element)(index, element);
        }
    }
    return FindResult!(Index, Element)(false);
}

/// Find all elements matching a predicate and get both those matching elements
/// and the indexes at which they were encountered.
auto findallelements(alias pred, Index = DefaultFindIndex, Iter)(
    Iter iter
) if(canFindElement!(pred, Index, Iter, true)){
    alias Element = ElementType!Iter;
    alias Result = FindResult!(Index, Element);
    Result[] results;
    Index index;
    foreach(element; iter){
        if(pred(element)){
            results ~= FindResult!(Index, Element)(index, element);
        }
        index++;
    }
    return results;
}



auto findfirstrandomaccess(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindRandomAccess!(pred, Index, Iter, Find, true)){
    return findgeneralized!(true, true, false, pred, Index)(iter, subject);
}

auto findlastrandomaccess(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindRandomAccess!(pred, Index, Iter, Find, false)){
    return findgeneralized!(false, true, false, pred, Index)(iter, subject);
}

auto findallrandomaccess(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindRandomAccess!(pred, Index, Iter, Find, true)){
    return findgeneralized!(true, true, true, pred, Index)(iter, subject);
}

auto findfirstsaving(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindSaving!(pred, Index, Iter, Find, true)){
    auto range = subject.asrange;
    return findgeneralized!(true, false, false, pred, Index)(iter, range);
}

auto findlastsaving(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindSaving!(pred, Index, Iter, Find, false)){
    auto range = subject.asrange;
    return findgeneralized!(false, false, false, pred, Index)(iter, range);
}

auto findallsaving(alias pred, Index = DefaultFindIndex, Iter, Find)(
    Iter iter, Find subject
) if(canFindSaving!(pred, Index, Iter, Find, true)){
    auto range = subject.asrange;
    return findgeneralized!(true, false, true, pred, Index)(iter, range);
}







template canFindGeneralized(
    bool randomaccess, alias pred, Index, Iter, Find, bool forward
){
    static if(randomaccess){
        enum bool canFindGeneralized = canFindRandomAccess!(pred, Index, Iter, Find, forward);
    }else{
        enum bool canFindGeneralized = canFindSavingRange!(pred, Index, Iter, Find, forward);
    }
}

/// Implements find with boolean template options for finding forwards or
/// backwards, using random access or saving ranges.
template findgeneralized(
    bool forward, bool randomaccess, bool all, alias pred, Index = DefaultFindIndex
){
    import mach.traits : canSliceSame;
    auto findgeneralized(Iter, Find)(Iter iter, Find subject) if(
        canFindGeneralized!(randomaccess, pred, Index, Iter, Find, forward)
    ){
        // If the range being searched in can be sliced, the result holds the
        // matched range. Otherwise the result only provides an index.
        static if(canSliceSame!Iter){
            alias Result = FindResult!(Index, typeof(Iter.init[0 .. 0]));
        }else{
            alias Result = FindResultIndex!Index;
        }
        
        static if(all) Result[] results;
        
        auto findlen = subject.length;
        
        if(findlen <= 0){
            static if(all) return results;
            else return Result(false);
        }
        
        static if(randomaccess){
            if(subject.length <= 0){
                static if(all) return results;
                else return Result(false);
            }
            alias Thread = FindRandomAccessThread!(pred, forward, Index);
            auto findfirst = subject[forward ? 0 : findlen - 1];
        }else{
            if(subject.empty){
                static if(all) return results;
                else return Result(false);
            }
            alias Thread = FindSavingThread!(pred, forward, Index, Find);
            auto findfirst = forward ? subject.front : subject.back;
        }
        
        auto threads = FindThreadManager!Thread(64);
        Index index = forward ? 0 : iter.length;
        Result result;
        
        bool step(Element)(ref Element element){
            // Progress living threads
            foreach(ref thread; threads){
                static if(randomaccess) bool matched = thread.next(element, subject);
                else bool matched = thread.next(element);
                if(matched){
                    result = thread.result(iter, index);
                    return true;
                }
            }
            // Spawn new threads
            if(pred(element, findfirst)){
                static if(randomaccess){
                    auto thread = Thread(index, forward ? 1 : findlen - 2);
                }else{
                    auto thread = Thread(index, subject.save);
                    static if(forward) thread.searchrange.popFront();
                    else thread.searchrange.popBack();
                }
                if(findlen == 1){
                    result = thread.result(iter, index);
                    return true;
                }
                threads.add(thread);
            }
            return false;
        }
        
        static if(forward){
            foreach(element; iter){
                if(step(element)){
                    static if(all) results ~= result;
                    else return result;
                }
                index++;
            }
        }else{
            foreach_reverse(element; iter){
                if(step(element)){
                    static if(all) results ~= result;
                    else return result;
                }
                index--;
            }
        }
        
        static if(all) return results;
        else return Result(false);
    }
}







version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Find", {
        tests("Element", {
            alias isdigit = (ch) => (ch >= '0' && ch <= '9');
            alias nomatch = (e) => (false);
            auto input = "a0b1a";
            tests("Given predicate", {
                tests("First", {
                    auto result = input.find!isdigit;
                    test(result.exists);
                    testeq(result.index, 1);
                    testeq(result.value, '0');
                    auto none = input.find!nomatch;
                    testf(none.exists);
                });
                tests("Last", {
                    auto result = input.findlast!isdigit;
                    test(result.exists);
                    testeq(result.index, 3);
                    testeq(result.value, '1');
                    auto none = input.findlast!nomatch;
                    testf(none.exists);
                });
                tests("All", {
                    auto result = input.findall!isdigit;
                    testeq("Length", result.length, 2);
                    test(result[0].exists);
                    testeq(result[0].index, 1);
                    testeq(result[0].value, '0');
                    test(result[1].exists);
                    testeq(result[1].index, 3);
                    testeq(result[1].value, '1');
                    auto none = input.findall!nomatch;
                    testeq("Length", none.length, 0);
                });
            });
            tests("Default predicate", {
                tests("First", {
                    auto result = input.find('0');
                    testeq(result.index, 1);
                    testeq(result.value, '0');
                });
                tests("Last", {
                    auto result = input.findlast('1');
                    testeq(result.index, 3);
                    testeq(result.value, '1');
                });
                tests("All", {
                    auto result = input.findall('a');
                    testeq("Length", result.length, 2);
                    testeq(result[0].index, 0);
                    testeq(result[0].value, 'a');
                    testeq(result[1].index, 4);
                    testeq(result[1].value, 'a');
                });
            });
        });
        tests("Iterable", {
            alias nomatch = (a, b) => (false);
            auto input = "hi_hi";
            auto sub = "hi";
            tests("Random access", {
                tests("First", {
                    auto result = input.find(sub);
                    test(result.exists);
                    testeq(result.index, 0);
                    testeq(result.value, "hi");
                });
                tests("Last", {
                    auto result = input.findlast(sub);
                    test(result.exists);
                    testeq(result.index, 3);
                    testeq(result.value, "hi");
                });
                tests("All", {
                    auto result = input.findall(sub);
                    testeq("Length", result.length, 2);
                    test(result[0].exists);
                    testeq(result[0].index, 0);
                    testeq(result[0].value, "hi");
                    test(result[1].exists);
                    testeq(result[1].index, 3);
                    testeq(result[1].value, "hi");
                    auto none1 = input.findall("notpresent");
                    testeq("Length", none1.length, 0);
                    auto none2 = input.findall!nomatch(sub);
                    testeq("Length", none2.length, 0);
                });
            });
            tests("Saving", {
                alias eq = (a, b) => (a == b);
                tests("First", {
                    auto result = input.findfirstsaving!eq(sub);
                    test(result.exists);
                    testeq(result.index, 0);
                    testeq(result.value, "hi");
                });
                tests("Last", {
                    auto result = input.findlastsaving!eq(sub);
                    test(result.exists);
                    testeq(result.index, 3);
                    testeq(result.value, "hi");
                });
                tests("All", {
                    auto result = input.findallsaving!eq(sub);
                    testeq("Length", result.length, 2);
                    test(result[0].exists);
                    testeq(result[0].index, 0);
                    testeq(result[0].value, "hi");
                    test(result[1].exists);
                    testeq(result[1].index, 3);
                    testeq(result[1].value, "hi");
                    auto none1 = input.findallsaving!eq("notpresent");
                    testeq("Length", none1.length, 0);
                    auto none2 = input.findallsaving!nomatch(sub);
                    testeq("Length", none2.length, 0);
                });
            });
        });
    });
}
