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



enum canFindAllEager(alias pred, Index, Iter, Subject) = (
    canFindIterable!(pred, Index, Iter, Subject, true)
);

enum canFindIterable(alias pred, Index, Iter, Subject, bool forward = true) = (
    canFindRandomAccess!(pred, Index, Iter, Subject, forward) ||
    canFindSaving!(pred, Index, Iter, Subject, forward)
);

enum canFindRandomAccess(alias pred, Index, Iter, Subject, bool forward = true) = (
    canFindIn!(Iter, forward) && validFindIndex!Index &&
    hasNumericIndex!Subject && hasNumericLength!Subject &&
    isPredicate!(pred, ElementType!Iter, ElementType!Subject)
);

enum canFindSaving(alias pred, Index, Iter, Subject, bool forward = true) = (
    canFindIn!(Iter, forward) && validFindIndex!Index &&
    validAsSavingRange!Subject && (forward || validAsBidirectionalRange!Subject) &&
    isPredicate!(pred, ElementType!Iter, ElementType!Subject)
);

enum canFindSavingRange(alias pred, Index, Iter, Subject, bool forward = true) = (
    isRange!Subject && canFindSaving!(pred, Index, Iter, Subject, forward)
);



auto findfirstiter(
    alias pred = DefaultFindPredicate,
    Index = DefaultFindIndex, Iter, Subject
)(Iter iter, Subject subject) if(
    canFindIterable!(pred, Index, Iter, Subject, true)
){
    static if(canFindRandomAccess!(pred, Index, Iter, Subject, true)){
        return findfirstrandomaccess!(pred, Index, Iter, Subject)(iter, subject);
    }else{
        return findfirstsaving!(pred, Index, Iter, Subject)(iter, subject);
    }
}

auto findlastiter(
    alias pred = DefaultFindPredicate,
    Index = DefaultFindIndex, Iter, Subject
)(Iter iter, Subject subject) if(
    canFindIterable!(pred, Index, Iter, Subject, false)
){
    static if(canFindRandomAccess!(pred, Index, Iter, Subject, false)){
        return findlastrandomaccess!(pred, Index, Iter, Subject)(iter, subject);
    }else{
        return findlastsaving!(pred, Index, Iter, Subject)(iter, subject);
    }
}

auto findallitereager(
    alias pred = DefaultFindPredicate,
    Index = DefaultFindIndex, Iter, Subject
)(Iter iter, Subject subject) if(
    canFindIterable!(pred, Index, Iter, Subject, true)
){
    static if(canFindRandomAccess!(pred, Index, Iter, Subject, true)){
        return findallrandomaccess!(pred, Index, Iter, Subject)(iter, subject);
    }else{
        return findallsaving!(pred, Index, Iter, Subject)(iter, subject);
    }
}



auto findfirstrandomaccess(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindRandomAccess!(pred, Index, Iter, Subject, true)){
    return findgeneralized!(true, true, false, pred, Index)(iter, subject);
}

auto findlastrandomaccess(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindRandomAccess!(pred, Index, Iter, Subject, false)){
    return findgeneralized!(false, true, false, pred, Index)(iter, subject);
}

auto findallrandomaccess(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindRandomAccess!(pred, Index, Iter, Subject, true)){
    return findgeneralized!(true, true, true, pred, Index)(iter, subject);
}

auto findfirstsaving(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindSaving!(pred, Index, Iter, Subject, true)){
    auto range = subject.asrange;
    return findgeneralized!(true, false, false, pred, Index)(iter, range);
}

auto findlastsaving(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindSaving!(pred, Index, Iter, Subject, false)){
    auto range = subject.asrange;
    return findgeneralized!(false, false, false, pred, Index)(iter, range);
}

auto findallsaving(alias pred, Index = DefaultFindIndex, Iter, Subject)(
    Iter iter, Subject subject
) if(canFindSaving!(pred, Index, Iter, Subject, true)){
    auto range = subject.asrange;
    return findgeneralized!(true, false, true, pred, Index)(iter, range);
}



private template canFindGeneralized(
    bool randomaccess, alias pred, Index, Iter, Subject, bool forward
){
    static if(randomaccess){
        enum bool canFindGeneralized = (
            canFindRandomAccess!(pred, Index, Iter, Subject, forward)
        );
    }else{
        enum bool canFindGeneralized = (
            canFindSavingRange!(pred, Index, Iter, Subject, forward)
        );
    }
}

/// Implements find with boolean template options for finding forwards or
/// backwards, using random access or saving ranges.
private template findgeneralized(
    bool forward, bool randomaccess, bool all, alias pred, Index = DefaultFindIndex
){
    import mach.traits : SliceType, canSliceSame;
    auto findgeneralized(Iter, Subject)(Iter iter, Subject subject) if(
        canFindGeneralized!(randomaccess, pred, Index, Iter, Subject, forward)
    ){
        // If the range being searched in can be sliced, the result holds the
        // matched range. Otherwise the result only provides an index.
        static if(canSliceSame!Iter){
            static if(all) alias Result = FindResultPlural!(Index, SliceType!(Iter, Index));
            else alias Result = FindResultSingular!(Index, SliceType!(Iter, Index));
        }else{
            static if(all) alias Result = FindResultIndexPlural!Index;
            else alias Result = FindResultIndexSingular!Index;
        }
        
        static if(all) Result[] results;
        
        auto subjectlen = subject.length;
        
        if(subjectlen <= 0){
            static if(all) return results;
            else return Result(false);
        }
        
        static if(randomaccess){
            if(subject.length <= 0){
                static if(all) return results;
                else return Result(false);
            }
            alias Thread = FindRandomAccessThread!(pred, forward, Index);
            auto findfirst = subject[forward ? 0 : subjectlen - 1];
        }else{
            if(subject.empty){
                static if(all) return results;
                else return Result(false);
            }
            alias Thread = FindSavingThread!(pred, forward, Index, Subject);
            auto findfirst = forward ? subject.front : subject.back;
        }
        
        auto threads = FindThreadManager!Thread(64);
        Index index = forward ? 0 : iter.length;
        Result result;
        
        bool step(Element)(ref Element element){
            auto found = false;
            // Progress living threads
            foreach(ref thread; threads){
                static if(randomaccess) bool matched = thread.next(element, subject);
                else bool matched = thread.next(element);
                if(matched){
                    result = cast(Result) thread.result(iter, index);
                    found = true;
                }
            }
            // Spawn new threads
            if(pred(element, findfirst)){
                static if(randomaccess){
                    auto thread = Thread(index, forward ? 1 : subjectlen - 2);
                }else{
                    auto thread = Thread(index, subject.save);
                    static if(forward) thread.searchrange.popFront();
                    else thread.searchrange.popBack();
                }
                if(subjectlen == 1){
                    result = cast(Result) thread.result(iter, index);
                    found = true;
                }else{
                    threads.add(thread);
                }
            }
            return found;
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
    template FindEagerTests(alias firstfunc, alias lastfunc, alias allfunc){
        void FindEagerTests(){
            alias nomatch = (a, b) => (false);
            alias eq = (a, b) => (a == b);
            auto input = "hi_hi";
            auto sub = "hi";
            tests("First", {
                auto result = firstfunc!eq(input, sub);
                test(result.exists);
                testeq(result.index, 0);
                testeq(result.value, "hi");
            });
            tests("Last", {
                auto result = lastfunc!eq(input, sub);
                test(result.exists);
                testeq(result.index, 3);
                testeq(result.value, "hi");
            });
            tests("All", {
                auto result = allfunc!eq(input, sub);
                testeq("Length", result.length, 2);
                testeq(result[0].index, 0);
                testeq(result[0].value, "hi");
                testeq(result[1].index, 3);
                testeq(result[1].value, "hi");
                auto none1 = allfunc!eq(input, "notpresent");
                testeq("Length", none1.length, 0);
                auto none2 = allfunc!nomatch(input, sub);
                testeq("Length", none2.length, 0);
                tests("Single-length subject", {
                    auto result = allfunc!eq("abcabc", "a");
                    testeq(result.length, 2);
                    testeq(result[0].index, 0);
                    testeq(result[0].value, "a");
                    testeq(result[1].index, 3);
                    testeq(result[1].value, "a");
                });
                tests("Overlapping", {
                    auto result = allfunc!eq("etetet", "etet");
                    testeq(result.length, 2);
                    testeq(result[0].index, 0);
                    testeq(result[0].value, "etet");
                    testeq(result[1].index, 2);
                    testeq(result[1].value, "etet");
                });
            });
        }
    }
}
unittest{
    tests("Find eager", {
        tests("Random access", {
            FindEagerTests!(
                findfirstrandomaccess,
                findlastrandomaccess,
                findallrandomaccess
            )();
        });
        tests("Saving", {
            FindEagerTests!(
                findfirstsaving,
                findlastsaving,
                findallsaving
            )();
        });
    });
}
