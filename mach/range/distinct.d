module mach.range.distinct;

private:

import mach.traits : ElementType, isIterable, isRange, isSavingRange;
import mach.traits : hasNumericLength, canHash, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin;
import mach.collect : DenseHashSet;

public:



/// Determine whether a `by` function is valid for some iterable.
enum validDistinctBy(Iter, alias by) = (
    canHash!(typeof(by(ElementType!Iter.init)))
);

/// Determine whether a `makehistory` function is valid for some iterable.
template validDistinctMakeHistory(Iter, alias by, alias makehistory){
    static if(isIterable!Iter){
        alias ByType = typeof(by(ElementType!Iter.init));
        enum bool validDistinctMakeHistory = is(typeof({
            auto history = makehistory!by(Iter.init);
            history.add(ByType.init);
            if(ByType.init in history) return;
        }));
    }else{
        enum bool validDistinctMakeHistory = false;
    }
}

enum canDistinct(
    Iter, alias by = DefaultDistinctBy,
    alias makehistory = DefaultDistinctMakeHistory
) = (
    validAsRange!Iter && validDistinctBy!(Iter, by) &&
    validDistinctMakeHistory!(Iter, by, makehistory)
);

enum canDistinctRange(
    Range, alias by = DefaultDistinctBy,
    alias makehistory = DefaultDistinctMakeHistory
) = (
    isRange!Range && canDistinct!(Range, by, makehistory)
);

alias DefaultDistinctBy = (element) => (element);



/// Default for makehistory argument of distinct range. Given an iterable and
/// a `by` function, any function passed for that argument should return an
/// object supporting both `history.add(element)` and `element in history`
/// syntax, such as a set.
auto DefaultDistinctMakeHistory(alias by, Iter)(auto ref Iter iter){
    alias ByType = typeof(by(ElementType!Iter.init));
    enum hasLength = hasNumericLength!Iter;
    DenseHashSet!(ByType, !hasLength) history;
    static if(hasLength) history.reserve(iter.length * 4);
    return history;
}



/// Create a range which returns only those values from the original iterable
/// that are distinct from all previous values. By default, each element itself
/// is tested for uniqueness; however an attribute of some element can be tested
/// for uniqueness by providing a different by alias. For example,
/// `input.distinct!((e) => (e.name))` would iterate over those elements of
/// input having distinct names.
auto distinct(alias by = DefaultDistinctBy, alias makehistory = DefaultDistinctMakeHistory, Iter)(
    auto ref Iter iter
) if(canDistinct!(Iter, by, makehistory)){
    auto range = iter.asrange;
    return DistinctRange!(typeof(range), by, makehistory)(range);
}



struct DistinctRange(
    Range, alias by = DefaultDistinctBy,
    alias makehistory = DefaultDistinctMakeHistory
) if(canDistinctRange!(Range, by, makehistory)){
    mixin MetaRangeEmptyMixin!Range;
    
    alias History = typeof(makehistory!by(Range.init));
    
    Range source;
    History history;
    
    this(Range source){
        this(source, makehistory!by(source));
    }
    this(Range source, History history){
        this.source = source;
        this.history = history;
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.history.add(by(this.source.front));
        this.source.popFront();
        while(!this.source.empty && by(this.source.front) in this.history){
            this.source.popFront();
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.history);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Distinct", {
        tests("Basic iteration", {
            test("aabacba".distinct.equals("abc"));
            test("nnnnnnnnnnnnnnn".distinct.equals("n"));
            test("hi".distinct.equals("hi"));
            test("x".distinct.equals("x"));
            test("".distinct.equals(""));
        });
        tests("Saving", {
            auto range = "aabc".distinct;
            auto saved = range.save;
            range.popFront();
            testeq(range.front, 'b');
            testeq(saved.front, 'a');
        });
        tests("By", {
            auto pairs = [
                [0, 1], [0, 2], [0, 3],
                [1, 1], [1, 2], [1, 3]
            ];
            auto range = pairs.distinct!((pair) => (pair[0]));
            test(range.equals([[0, 1], [1, 1]]));
        });
    });
}
