module mach.range.tap;

private:

import mach.traits : isRange, isIterable, ElementType, isRandomAccessRange;
import mach.traits : isBidirectionalRange, isSavingRange, isSlicingRange;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

/++ Docs

The `tap` function lazily applies a callback function to each element in an
input iterable. It accepts an input iterable valid as a range for its single
runtime argument, and it accepts a template argument representing the function
to apply to the input's elements as the range is consumed.

When the input is bidirectional, so is the range produced by `tap`.
It provides `length` and `remaining` properties when the input does,
and propagates infiniteness.
It supports random access and slicing operations when the input does.

The outputted range applies the callback upon each element being popped,
not upon access or assignment.
If the range's elements are removed, then those elements are consumed without
the callback being applied to them.

For an eagerly-evaluated analog to `tap`, see `each` in `mach.range.each`.

+/

unittest{ /// Example
    import mach.range.consume : consume;
    string hello;
    auto range = "hello".tap!((ch){hello ~= ch;});
    range.consume;
    assert(hello == "hello");
}

unittest{
    // Create a range which throws an error when the callback is applied.
    auto range = "hello".tap!((e){assert(false);});
    // Accessing elements doesn't trigger the callback!
    assert(range.front == 'h');
    assert(range.back == 'o');
    assert(range[1] == 'e');
    assert(range[0 .. $][2] == 'l');
}

unittest{ /// Example
    int[] array;
    // Produce a range which appends to `array` as elements are consumed.
    auto range = [1, 2, 3, 4].tap!((n){array ~= n;});
    assert(range.front == 1);
    assert(array.length == 0);
    range.popFront(); // The callback is applied upon popping.
    assert(array == [1]);
    while(!range.empty) range.popFront();
    assert(array == [1, 2, 3, 4]);
}

unittest{ /// Example
    import mach.collect : DoublyLinkedList;
    // The callback appends elements to this array.
    int[] array;
    // Use a range produced from a list because it supports removal of elements.
    auto list = new DoublyLinkedList!int([1, 2, 3, 4]);
    auto range = list.values.tap!((n){array ~= n;});
    // The callback is applied to the front value upon popping it.
    range.popFront();
    assert(array == [1]);
    // And the callback is applied to the back value upon popping it.
    range.popBack();
    assert(array == [1, 4]);
    // When assigning elements, the callback is applied to the new value.
    range.front = 10;
    range.popFront();
    assert(array == [1, 4, 10]);
    // When removing elements, the callback is not applied.
    range.removeFront();
    assert(array == [1, 4, 10]);
}

public:



alias canTap = isIterable;
alias canTapRange = isRange;



/// Returns a range which applies a callback every time an element is popped.
auto tap(alias func, Iter)(auto ref Iter iter) if(canTap!Iter){
    auto range = iter.asrange;
    return TapRange!(func, typeof(range))(range);
}



struct TapRange(alias func, Range) if(canTapRange!Range){
    /// The range element type.
    alias Element = ElementType!Range;
    /// The callback function, applied to elements of the source range.
    alias apply = func;
    
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    Range source;
    
    this(Range source){
        this.source = source;
    }
    
    /// Get the front element.
    @property auto front(){
        return this.source.front;
    }
    /// Apply the callback to the front element and then pop it.
    void popFront(){
        func(this.source.front);
        this.source.popFront();
    }
    
    static if(isBidirectionalRange!Range){
        /// Get the back element.
        @property auto back(){
            return this.source.back;
        }
        /// Apply the callback to the back element and then pop it.
        void popBack(){
            func(this.source.back);
            this.source.popBack();
        }
    }
    
    auto opIndex(Args...)(Args args) if(is(typeof({
        return this.source[args];
    }))){
        return this.source[args];
    }
    auto opIndexAssign(Args...)(Args args) if(is(typeof({
        return this.source[args[1 .. $]] = args[0];
    }))){
        return this.source[args[1 .. $]] = args[0];
    }
    
    static if(isSlicingRange!Range){
        typeof(this) opSlice(in size_t low, in size_t high){
            return typeof(this)(this.source[low .. high]);
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save);
        }
    }
    
    static enum bool mutable = isMutableRange!Range;
    
    static if(isMutableFrontRange!Range){
        /// Reassign the front element of the range.
        /// The callback, when evaluated, will be applied to the new front
        /// element and not to the prior one.
        @property void front(Element element){
            this.source.front = element;
        }
    }
    static if(isMutableBackRange!Range){
        /// Reassign the back element of the range.
        /// The callback, when evaluated, will be applied to the new back
        /// element and not to the prior one.
        @property void back(Element element){
            this.source.back = element;
        }
    }
    static if(isMutableRemoveFrontRange!Range){
        /// Remove the front element, without applying the callback function.
        void removeFront(){
            this.source.removeFront();
        }
    }
    static if(isMutableRemoveBackRange!Range){
        /// Remove the back element, without applying the callback function.
        void removeBack(){
            this.source.removeBack();
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.collect : DoublyLinkedList;
}
unittest{
    tests("Tap", {
        tests("Bidirectionality", {
            int[] ints;
            auto range = [0, 1, 2, 3].tap!((n){ints ~= n;});
            testf(range.empty);
            testeq(range.length, 4);
            testeq(range.remaining, 4);
            testeq(range.front, 0);
            range.popFront();
            testeq(ints, [0]);
            testeq(range.length, 4);
            testeq(range.remaining, 3);
            testeq(range.back, 3);
            range.popBack();
            testeq(ints, [0, 3]);
            testeq(range.remaining, 2);
            testeq(range.back, 2);
            range.popFront();
            testeq(ints, [0, 3, 1]);
            testeq(range.front, 2);
            testeq(range.remaining, 1);
            range.popBack();
            testeq(ints, [0, 3, 1, 2]);
            testeq(range.remaining, 0);
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront();});
            testfail({range.back;});
            testfail({range.popBack();});
        });
        tests("Iteration", {
            tests("Empty", {
                test(new int[0].tap!((e){}).empty);
            });
            tests("Not empty", {
                auto array = [0, 1, 2, 3];
                test!equals(array.tap!((e){}), array);
            });
        });
        tests("Callback", {
            auto input = "hello world";
            string forwards = "";
            string backwards = "";
            auto range = input.tap!((ch){
                forwards ~= ch;
                backwards = ch ~ backwards;
            });
            testeq(range.length, input.length);
            while(!range.empty) range.popFront();
            testeq(forwards, input);
            testeq(backwards, "dlrow olleh");
        });
        tests("Random access", {
            auto range = [0, 1, 2, 3].tap!((e){assert(false);});
            testeq(range[0], 0);
            testeq(range[1], 1);
            testeq(range[2], 2);
            testeq(range[$-1], 3);
            testfail({range[$];});
        });
        tests("Slicing", {
            auto range = [0, 1, 2, 3].tap!((e){});
            test(range[0 .. 0].empty);
            test(range[$ .. $].empty);
            test!equals(range[0 .. 2], [0, 1]);
            testfail({range[0 .. $+1];});
        });
        tests("Saving", {
            auto range = [0, 1, 2, 3].tap!((e){});
            auto saved = range.save;
            range.popFront();
            testeq(range.front, 1);
            testeq(saved.front, 0);
        });
        tests("Mutation", {
            auto ints = [0, 1, 2, 3];
            auto range = ints.tap!((e){assert(false);});
            // Mutate front
            range.front = 10;
            testeq(range.front, 10);
            testeq(ints[0], 10);
            // Mutate back
            range.back = 20;
            testeq(range.back, 20);
            testeq(ints[$-1], 20);
            // Random access
            range[0] = 5;
            testeq(range[0], 5);
            testeq(ints[0], 5);
            testfail({range[$] = 1;});
        });
        tests("Removal", {
            auto list = new DoublyLinkedList!int([0, 1, 2, 3]);
            auto range = list.values.tap!((e){assert(false);});
            // Callback fails; element isn't popped
            testfail({range.popFront();});
            testeq(range.front, 0);
            // Removal doesn't invoke the callback
            range.removeFront();
            testeq(range.front, 1);
            test!equals(list.ivalues, [1, 2, 3]);
            range.removeBack();
            testeq(range.back, 2);
            test!equals(list.ivalues, [1, 2]);
        });
    });
}
