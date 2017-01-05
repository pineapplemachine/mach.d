module mach.range.distinct;

private:

import mach.traits : ElementType, isIterable, isRange, isSavingRange;
import mach.traits : hasNumericLength, canHash, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin;
import mach.collect : DenseHashSet;

public:



/// Determine whether a `by` function is valid for some iterable.
template validDistinctBy(T, alias by){
    enum bool validDistinctBy = canHash!(typeof(by((ElementType!T).init)));
}

alias DefaultDistinctBy = (e) => (e);
static assert(validDistinctBy!(int[], DefaultDistinctBy));



template canDistinct(T, alias by = DefaultDistinctBy){
    enum bool canDistinct = validAsRange!T && validDistinctBy!(T, by);
}

template canDistinctRange(T, alias by = DefaultDistinctBy){
    enum bool canDistinctRange = isRange!T && canDistinct!(T, by);
}



/// Create a range which returns only those values from the original iterable
/// that are distinct from all previous values. By default, each element itself
/// is tested for uniqueness; however an attribute of some element can be tested
/// for uniqueness by providing a different by alias. For example,
/// `input.distinct!((e) => (e.name))` would iterate over those elements of
/// input having distinct names.
auto distinct(alias by = DefaultDistinctBy, Iter)(auto ref Iter iter) if(
    canDistinct!(Iter, by)
){
    auto range = iter.asrange;
    return DistinctRange!(typeof(range), by)(range);
}



struct DistinctRange(
    Range, alias by = DefaultDistinctBy
) if(canDistinctRange!(Range, by)){
    mixin MetaRangeEmptyMixin!Range;
    
    alias History = DenseHashSet!(typeof(by(ElementType!Range.init)));
    
    Range source;
    History* history;
    
    this(Range source){
        this(source, new History());
        this.history.accommodate(source);
    }
    this(Range source, History* history){
        this.source = source;
        this.history = history;
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.history.add(by(this.source.front));
        this.source.popFront();
        while(!this.source.empty && this.history.contains(by(this.source.front))){
            this.source.popFront();
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.history.dup);
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
