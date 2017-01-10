module mach.range.cache;

public:

import mach.types : Rebindable;
import mach.traits : ElementType, isRange, isSlicingRange, isSavingRange;
import mach.traits : isBidirectionalRange, isMutableRange, isMutableFrontRange;
import mach.traits : isMutableBackRange, isMutableRandomRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;
import mach.range.asrange : asrange, validAsRange;

/++ Docs

The `cache` function produces a range which enumerates the elements of its
input, but in such a way that the `front` or `back` properties of the input
range (or the range constructed from an input iterable) are called only once
per element.

This may be useful when the `front` or `back` methods of an input range are
costly to compute, but can be expected to be accessed more than once.
This benefit would also apply to transient ranges for which, contrary to the
standard, accessing `front` or `back` also consumes that element.

+/

unittest{ /// Example
    import mach.error.mustthrow : mustthrow;
    // A range which causes an error when `front` is accessed more than once.
    struct Test{
        enum bool empty = false;
        int element = 0;
        bool accessed = false;
        @property auto front(){
            assert(!this.accessed);
            this.accessed = true;
            return this.element;
        }
        void popFront(){
            this.accessed = false;
        }
    }
    // For example:
    mustthrow({
        Test test;
        test.front;
        test.front;
    });
    // But, using `cache`:
    auto range = Test(0).cache;
    assert(range.front == 0);
    assert(range.front == 0); // Repeated access ok!
}

private:



/// Get a range which enumerates the values of the input, but stores the
/// front and back (when available) once so that, on successive invokations of
/// the properties, whatever logic is performed in the source range does not
/// have to be repeated.
auto cache(Iter)(auto ref Iter iter) if(validAsRange!Iter){
    auto range = iter.asrange;
    return CacheRange!(typeof(range))(range);
}



/// Range for enumerating the values of an input, only referring to the
/// source's front and back properties once per element.
struct CacheRange(Range) if(isRange!Range){
    enum bool isBidirectional = isBidirectionalRange!Range;
    alias Element = ElementType!Range;
    alias CachedElement = Rebindable!(Element);
    
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    /// The source range being enumerated.
    Range source;
    /// The current front element of the range.
    CachedElement cachedfront;
    /// The current back element of the range.
    static if(isBidirectional) CachedElement cachedback;
    
    this(Range source){
        this.source = source;
        if(!this.source.empty){
            this.cachedfront = this.source.front;
            static if(isBidirectional) this.cachedback = this.source.back;
        }
    }
    
    static if(!isBidirectional) this(
        Range source, CachedElement cachedfront
    ){
        this.source = source;
        this.cachedfront = cachedfront;
    }
    static if(isBidirectional) this(
        Range source, CachedElement cachedfront, CachedElement cachedback
    ){
        this.source = source;
        this.cachedfront = cachedfront;
        this.cachedback = cachedback;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return cast(Element) this.cachedfront;
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
        if(!this.source.empty) this.cachedfront = this.source.front;
    }
    
    static if(isBidirectional){
        @property auto back() in{assert(!this.empty);} body{
            return cast(Element) this.cachedback;
        }
        void popBack() in{assert(!this.empty);} body{
            this.source.popBack();
            if(!this.source.empty) this.cachedback = this.source.back;
        }
    }
    
    /// Return the element at an index.
    /// Does not cache the element returned by the source range.
    auto opIndex(Args...)(Args args) if(is(typeof({
        return this.source[args];
    }))){
        return this.source[args];
    }
    
    static if(isSlicingRange!Range){
        auto opSlice(in size_t low, in size_t high){
            return typeof(this)(this.source[low .. high]);
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source, this.cachedfront, this.cachedback);
        }
    }
    
    enum bool mutable = isMutableRange!Range;
    
    static if(isMutableFrontRange!Range){
        @property void front(Element value) in{assert(!this.empty);} body{
            this.source.front = value;
            this.cachedfront = value;
        }
    }
    static if(isMutableBackRange!Range){
        @property void back(Element value) in{assert(!this.empty);} body{
            this.source.back = value;
            this.cachedback = value;
        }
    }
    static if(isMutableRandomRange!Range){
        void opIndexAssign(Element value, in size_t index){
            this.source[index] = value;
        }
    }
    static if(isMutableRemoveFrontRange!Range){
        void removeFront() in{assert(!this.empty);} body{
            this.source.removeFront();
            if(!this.source.empty) this.cachedfront = this.source.front;
        }
    }
    static if(isMutableRemoveBackRange!Range){
        void removeBack() in{assert(!this.empty);} body{
            this.source.removeBack();
            if(!this.source.empty) this.cachedback = this.source.back;
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.collect : DoublyLinkedList;
    /// Raise an AssertError upon attempting to access the front or back element
    /// more than once before popping.
    /// This helps make sure `cache` only ever accesses the elements once.
    auto tricky(T)(auto ref T iter){
        auto range = iter.asrange;
        return TrickyRange!(typeof(range))(range);
    }
    struct TrickyRange(Source){
        Source source;
        bool accessedfront = false;
        bool accessedback = false;
        @property auto length(){
            return this.source.length;
        }
        @property auto remaining(){
            return this.source.remaining;
        }
        @property bool empty(){
            return this.source.empty;
        }
        @property auto front(){
            assert(!this.accessedfront);
            this.accessedfront = true;
            return this.source.front;
        }
        void popFront(){
            this.accessedfront = false;
            this.source.popFront();
        }
        @property auto back(){
            assert(!this.accessedback);
            this.accessedback = true;
            return this.source.back;
        }
        void popBack(){
            this.accessedback = false;
            this.source.popBack();
        }
        @property typeof(this) save(){
            return typeof(this)(this.source.save);
        }
    }
}
unittest{
    tests("Cache", {
        tests("Iteration", {
            auto range = [0, 1, 2, 3].tricky.cache;
            foreach(element; range){}
        });
        tests("Bidirectionality", {
            auto range = [0, 1, 2, 3].tricky.cache;
            testeq(range.length, 4);
            testeq(range.remaining, 4);
            testeq(range.front, 0);
            testeq(range.front, 0);
            testeq(range.back, 3);
            testeq(range.back, 3);
            range.popFront();
            testeq(range.length, 4);
            testeq(range.remaining, 3);
            testeq(range.front, 1);
            range.popBack();
            testeq(range.remaining, 2);
            testeq(range.back, 2);
            range.popFront();
            testeq(range.remaining, 1);
            testeq(range.front, 2);
            range.popBack();
            testeq(range.remaining, 0);
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront();});
            testfail({range.back;});
            testfail({range.popBack();});
        });
        tests("Saving", {
            auto range = [0, 1, 2, 3].tricky.cache;
            auto saved = range.save;
            range.popFront();
            testeq(range.front, 1);
            testeq(range.front, 1);
            testeq(saved.front, 0);
            testeq(saved.front, 0);
        });
        tests("Random access", {
            auto range = "hi".cache;
            testeq(range[0], 'h');
            testeq(range[1], 'i');
            testfail({range[2];});
        });
        tests("Slicing", {
            auto range = [0, 1, 2].cache;
            test(range[0 .. 0].empty);
            test(range[$ .. $].empty);
            test!equals(range[0 .. 1], [0]);
            test!equals(range[0 .. 2], [0, 1]);
            test!equals(range[0 .. $], [0, 1, 2]);
            test!equals(range[1 .. $], [1, 2]);
            test!equals(range[2 .. $], [2]);
            testfail({range[0 .. $+1];});
        });
        tests("Mutability", {
            auto array = [0, 1, 2];
            auto range = array.cache;
            range.front = 10;
            testeq(range.front, 10);
            testeq(range.front, 10);
            testeq(array, [10, 1, 2]);
            range.back = 20;
            testeq(range.back, 20);
            testeq(range.back, 20);
            testeq(array, [10, 1, 20]);
            range[1] = 15;
            testeq(range[1], 15);
            testeq(array, [10, 15, 20]);
        });
        tests("Removal", {
            auto list = new DoublyLinkedList!int([0, 1, 2]);
            auto range = list.values.cache;
            range.removeFront();
            testeq(range.front, 1);
            testeq(range.front, 1);
            test!equals(list.ivalues, [1, 2]);
            range.removeBack();
            testeq(range.back, 1);
            testeq(range.back, 1);
            test!equals(list.ivalues, [1]);
            range.removeFront();
            test(range.empty);
            test(list.empty);
        });
        tests("Immutable input", {
            const(const(int)[]) array = [0, 1, 2, 3];
            auto range = array.cache;
            testeq(range.front, 0);
            testeq(range.front, 0);
            foreach(element; range){}
        });
    });
}
