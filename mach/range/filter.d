module mach.range.filter;

private:

import mach.traits : ElementType, isRange, isBidirectionalRange, isSavingRange;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.range.asrange : asrange, validAsRange, AsRangeElementType;
import mach.range.meta : MetaRangeEmptyMixin;

public:



/// Get whether an input can be filtered.
template canFilter(T, alias pred){
    enum bool canFilter = validAsRange!T && is(typeof({
        if(pred(AsRangeElementType!T.init)){}
    }));
}

/// Get whether a `FilterRange` can be constructed from a given type.
template canFilterRange(T, alias pred){
    enum bool canFilterRange = isRange!T && canFilter!(T, pred);
}



/// Given an object that can be taken as a range, create a new range which
/// enumerates only those values of the original range matching some predicate.
auto filter(alias pred, Iter)(Iter iter) if(canFilter!(Iter, pred)){
    auto range = iter.asrange;
    return FilterRange!(pred, typeof(range))(range);
}



/// Range for filtering the elements of an input according to a predicate function.
struct FilterRange(alias pred, Range) if(canFilterRange!(Range, pred)){
    alias Element = typeof(Range.front);
    
    mixin MetaRangeEmptyMixin!Range;
    
    /// Represents the input being filtered.
    Range source;
    
    this(Range source){
        this.source = source;
        this.consumeFront();
        static if(isBidirectionalRange!Range) this.consumeBack();
    }
    
    /// Get the front element.
    @property auto front() in{assert(!this.empty);} body{
        return this.source.front;
    }
    /// Pop the front element.
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
        this.consumeFront();
    }
    /// Pop values from the source range until a value matching the
    /// predicate is found.
    void consumeFront(){
        while(!this.source.empty && !pred(this.source.front)){
            this.source.popFront();
        }
    }
    
    static if(isBidirectionalRange!Range){
        /// Get the back element.
        @property auto back() in{assert(!this.empty);} body{
            return this.source.back;
        }
        /// Pop the back element.
        void popBack() in{assert(!this.empty);} body{
            this.source.popBack();
            this.consumeBack();
        }
        /// Pop values from the source range until a value matching the
        /// predicate is found.
        void consumeBack(){
            while(!this.source.empty && !pred(this.source.back)){
                this.source.popBack();
            }
        }
    }
    
    static if(isSavingRange!Range){
        /// Save the range.
        @property typeof(this) save(){
            return typeof(this)(this.source.save);
        }
    }

    enum bool mutable = isMutableRange!Range;
    
    static if(isMutableFrontRange!Range){
        /// Set the front element.
        @property void front(Element value) in{assert(!this.empty);} body{
            this.source.front = value;
        }
    }
    static if(isMutableBackRange!Range){
        /// Set the back element.
        @property void back(Element value) in{assert(!this.empty);} body{
            this.source.back = value;
        }
    }
    static if(isMutableRemoveFrontRange!Range){
        /// Remove the front element.
        auto removeFront(){
            scope(exit) this.consumeFront();
            return this.source.removeFront();
        }
    }
    static if(isMutableRemoveBackRange!Range){
        /// Remove the back element.
        auto removeBack(){
            scope(exit) this.consumeBack();
            return this.source.removeBack();
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
    import mach.range.mutate : mutate;
    import mach.range.retro : retro;
    import mach.collect : DoublyLinkedList;
}
unittest{
    tests("Filter", {
        alias even = (n) => (n % 2 == 0);
        tests("Iteration", {
            auto empty = new int[0];
            test(empty.filter!even.equals(empty));
            test([0].filter!even.equals([0]));
            test([1].filter!even.equals(empty));
            test([1, 2, 3, 4, 5, 6].filter!even.equals([2, 4, 6]));
        });
        tests("Bidirectionality", {
            test([2, 4, 5].filter!even.retro.equals([4, 2]));
            auto range = [0, 1, 2, 3, 4].filter!even;
            testeq(range.back, 4);
            range.popBack();
            testeq(range.back, 2);
            range.popBack();
            testeq(range.back, 0);
            range.popBack();
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront();});
            testfail({range.back;});
            testfail({range.popBack();});
        });
        tests("Saving", {
            auto range = [0, 1, 2, 3].filter!even;
            auto saved = range.save;
            range.popFront();
            testeq(range.front, 2);
            testeq(saved.front, 0);
        });
        tests("Mutability", {
            tests("Mutation", {
                auto array = [1, 2, 3, 4, 5, 6];
                array.filter!even.mutate!((n) => (n - 1)).consume;
                testeq(array, [1, 1, 3, 3, 5, 5]);
            });
            tests("Mutation & Removal", {
                auto list = new DoublyLinkedList!int(0, 1, 2, 3, 4, 5);
                auto range = list.filter!(n => n % 2);
                testeq(range.front, 1);
                testeq(range.back, 5);
                range.front = 6;
                testeq(range.front, 6);
                test!equals(list.ivalues, [0, 6, 2, 3, 4, 5]);
                range.back = 7;
                testeq(range.back, 7);
                test!equals(list.ivalues, [0, 6, 2, 3, 4, 7]);
                range.removeFront();
                testeq(range.front, 3);
                test!equals(list.ivalues, [0, 2, 3, 4, 7]);
                range.removeBack();
                testeq(range.back, 3);
                test!equals(list.ivalues, [0, 2, 3, 4]);
                range.removeFront();
                test(range.empty);
                test!equals(list.ivalues, [0, 2, 4]);
                testfail({range.front = 0;});
                testfail({range.back = 0;});
                testfail({range.removeFront();});
                testfail({range.removeBack();});
            });
        });
    });
}
