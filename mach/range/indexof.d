module mach.range.indexof;

private:

import std.traits : isIntegral;
import mach.traits : isFiniteIterable;
import mach.range.asrange : asrange, validAsRange, validAsSavingRange;

public:



alias DefaultIndexOfIndex = ptrdiff_t;

alias DefaultIndexOfPredicate = (a, b) => (a == b);

alias validIndexOfIndex = isIntegral;

/// True if Sub can be searched for in Iter as a range.
enum bool canIndexOfRange(Iter, Sub, Index) = (
    isFiniteIterable!Iter &&
    validAsSavingRange!Sub &&
    validIndexOfIndex!Index
);

/// True if Sub can be searched for in Iter as an atomic element.
enum bool canIndexOfElement(Iter, Sub, Index) = (
    isFiniteIterable!Iter &&
    validIndexOfIndex!Index
);



/// Used by indexofrange to track potential hits.
private struct IndexOfThread(Index, Needle){
    Index index;
    Needle needle;
    bool alive;
}



/// Find the index of the first matching sequence of sub in iter, or -1 if none exists.
auto indexof(alias pred, Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    canIndexOfRange!(Iter, Sub, Index)
){
    return indexofrange!(pred, Index, Iter, Sub)(iter, sub);
}

/// Find the index of the first equal sequence of sub in iter, or -1 if none exists.
auto indexof(Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    canIndexOfRange!(Iter, Sub, Index)
){
    return indexofrange!(DefaultIndexOfPredicate, Index, Iter, Sub)(iter, sub);
}

/// Find the first element in iter matching sub, or -1 if none match.
auto indexof(alias pred, Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    !canIndexOfRange!(Iter, Sub, Index) && canIndexOfElement!(Iter, Sub, Index)
){
    return indexofelement!(pred, Index, Iter, Sub)(iter, sub);
}

/// Find the first element in iter equal to sub, or -1 if none are equal.
auto indexof(Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    !canIndexOfRange!(Iter, Sub, Index) && canIndexOfElement!(Iter, Sub, Index)
){
    return indexofelement!(DefaultIndexOfPredicate, Index, Iter, Sub)(iter, sub);
}



auto indexofrange(alias pred, Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    canIndexOfRange!(Iter, Sub, Index)
){
    auto needle = sub.asrange;
    
    if(needle.empty) return 0;
    
    alias Thread = IndexOfThread!(Index, typeof(needle));
    Thread[] threads;
    
    Index index = 0;
    
    foreach(ref item; iter){
        // TODO: Clean up old threads
        foreach(ref thread; threads){
            if(thread.alive){
                thread.alive = pred(item, thread.needle.front);
                thread.needle.popFront();
                if(thread.needle.empty){
                    if(thread.alive) return thread.index;
                    thread.alive = false;
                }
            }
        }
        
        if(pred(item, needle.front)){
            auto threadneedle = needle.save;
            threadneedle.popFront();
            if(threadneedle.empty) return index;
            threads ~= Thread(index, threadneedle, true);
        }
        
        index++;
    }
    
    return -1;
}

auto indexofrange(Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    canIndexOfRange!(Iter, Sub, Index)
){
    return indexofrange!(DefaultIndexOfPredicate, Index, Iter, Sub)(iter, sub);
}



auto indexofelement(alias pred, Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    canIndexOfElement!(Iter, Sub, Index)
){
    Index index = 0;
    foreach(item; iter){
        if(pred(item, sub)) return index;
        index++;
    }
    return -1;
}

auto indexofelement(Index = DefaultIndexOfIndex, Iter, Sub)(Iter iter, Sub sub) if(
    canIndexOfElement!(Iter, Sub, Index)
){
    return indexofelement!(DefaultIndexOfPredicate, Index, Iter, Sub)(iter, sub);
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Index of subrange in range", {
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
            testeq("hello".indexof(""), 0);
        });
        tests("Tricky", {
            testeq("xyzaxyzaxyzb".indexof("xyzaxyzb"), 4);
        });
    });
    tests("Index of atomic element in range", {
        testeq("hello".indexof('h'), 0);
        testeq("hello".indexof('e'), 1);
        testeq("hello".indexof('l'), 2);
        testeq("hello".indexof('o'), 4);
        testeq("hello".indexof('z'), -1);
    });
}
