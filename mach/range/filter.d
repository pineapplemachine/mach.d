module mach.range.filter;

private:

import mach.traits : ElementType, isRange, isBidirectionalRange;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canFilter(Iter, alias pred) = (
    validAsRange!Iter && validFilterPredicate!(Iter, pred)
);
enum canFilterRange(Range, alias pred) = (
    isRange!Range && validFilterPredicate!(Range, pred)
);

/// Determine whether some predicate can be applied to the elements of an iterable.
template validFilterPredicate(Iter, alias pred){
    enum bool validFilterPredicate = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto match = pred(Element.init);
        if(match){}
    }));
}



/// Given an object that can be taken as a range, create a new range which
/// enumerates only those values of the original range matching some predicate.
auto filter(alias pred, Iter)(Iter iter) if(canFilter!(Iter, pred)){
    auto range = iter.asrange;
    return FilterRange!(pred, typeof(range))(range);
}



struct FilterRange(alias pred, Range) if(canFilterRange!(Range, pred)){
    alias Element = typeof(Range.front);
    
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Save Back`
    );
    
    Range source;
    
    this(Range source){
        this.source = source;
        this.consumeFront();
        static if(isBidirectionalRange!Range) this.consumeBack();
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        this.source.popFront();
        this.consumeFront();
    }
    /// Pop values from source range until a matching value is found.
    void consumeFront(){
        while(!this.source.empty && !pred(this.source.front)){
            this.source.popFront();
        }
    }
    
    static if(isBidirectionalRange!Range){
        @property auto ref back(){
            return this.source.back;
        }
        void popBack(){
            this.source.popBack();
            this.consumeBack();
        }
        void consumeBack(){
            while(!this.source.empty && !pred(this.source.back)){
                this.source.popBack();
            }
        }
    }
    
    static if(isMutableRange!Range){
        enum bool mutable = true;
        static if(isMutableFrontRange!Range){
            @property void front(Element value){
                this.source.front = value;
            }
        }
        static if(isMutableBackRange!Range){
            @property void back(Element value){
                this.source.back = value;
            }
        }
    }else{
        enum bool mutable = false;
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
    import mach.range.mutate : mutate;
    import mach.range.reversed : reversed;
}
unittest{
    tests("Filter", {
        alias even = (n) => (n % 2 == 0);
        tests("Iteration", {
            test([1, 2, 3, 4, 5, 6].filter!even.equals([2, 4, 6]));
        });
        tests("Backwards", {
            test([2, 4, 5].filter!even.reversed.equals([4, 2]));
        });
        tests("Mutability", {
            auto array = [1, 2, 3, 4, 5, 6];
            array.filter!even.mutate!((n) => (n - 1)).consume;
            testeq(array, [1, 1, 3, 3, 5, 5]);
        });
    });
}
