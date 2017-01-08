module mach.range.enumerate;

private:

import mach.types : tuple;
import mach.traits : isRange, isSavingRange, isRandomAccessRange;
import mach.traits : isFiniteRange, isBidirectionalRange, isSlicingRange;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.traits : isMutableRandomRange, isMutableInsertRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.traits : hasNumericLength, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

/++ Docs

This module implements an `enumerate` function, which returns a range whose
elements are those of its source iterable, wrapped in a type that includes,
in addition to an element of the source iterable, a zero-based index
representing the location of that element within the iterable.

The elements of the range returned by `enumerate` behave like tuples.

+/

unittest{ /// Example
    auto array = ["hi", "how", "are", "you"];
    foreach(index, element; array.enumerate){
        assert(element == array[index]);
    }
}

unittest{ /// Example
    auto range = ["zero", "one", "two"].enumerate;
    assert(range.front.index == 0);
    assert(range.front.value == "zero");
}

/++ Docs

When the input iterable is bidirectional, so is the range outputted by
`enumerate`. The range provides `length` and `remaining` properties when
the input does, and propagates infiniteness. It supports random access and
slicing operators when the input iterable supports them, as well as
removal of elements.

The `enumerate` range allows mutation of its front and back elements, as well
as random access writing, using the element type of its input iterable.
They cannot be assigned using the element type of the range itself.

+/

unittest{ /// Example
    auto array = [0, 1, 2, 3];
    auto range = array.enumerate;
    // Values can be reassigned using the element type of the input iterable.
    range.front = 10;
    assert(range.front.value == 10);
    range.back = 20;
    assert(range.back.value == 20);
    // But not using the element type of the `enumerate` range.
    static assert(!is(typeof({
        range.front = range.back;
    })));
}

public:



/// Get whether an input can be enumerated.
template canEnumerate(T){
    enum bool canEnumerate = validAsRange!T;
}

/// Get whether an `EnumerationRange` can be constructed from a given type.
template canEnumerateRange(T){
    enum bool canEnumerateRange = isRange!T;
}

/// Get whether a bidirectional `EnumerationRange` can be constructed from
/// a given range type.
/// Requires that the range be bidirectional, finite, and have numeric length.
template canEnumerateRangeBidirectional(T){
    enum bool canEnumerateRangeBidirectional = (
        isBidirectionalRange!T &&
        isFiniteRange!T &&
        hasNumericLength!T
    );
}



/// Produce a range wrapping each element of an input iterable in a type
/// which includes an index indicating location of the element in that
/// input iterable.
auto enumerate(Iter)(auto ref Iter iter, in size_t initial = 0) if(
    canEnumerate!Iter
){
    auto range = iter.asrange;
    return EnumerationRange!(typeof(range))(range, initial);
}



/// Type representing an element of an `EnumerationRange`.
struct EnumerationRangeElement(T){
    size_t index;
    T value;
    @property auto astuple(){
        return tuple(this.index, this.value);
    }
    alias astuple this;
}

/// Range for enumerating the contents of a source range, including an index
/// representing the position of the current element in the source.
struct EnumerationRange(Range) if(canEnumerateRange!Range){
    alias Element = EnumerationRangeElement!(ElementType!Range);
    static enum bool isBidirectional = canEnumerateRangeBidirectional!Range;
    
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    Range source;
    size_t frontindex;
    static if(isBidirectional) size_t backindex;
    
    this(typeof(this) range){
        static if(isBidirectional){
            this(range.source, range.frontindex, range.backindex);
        }else{
            this(range.source, range.frontindex);
        }
    }
    this(Range source, size_t frontinitial = 0){
        static if(isBidirectional){
            size_t backinitial = cast(size_t) source.length;
            backinitial--;
            this(source, frontinitial, backinitial);
        }else{
            this.source = source;
            this.frontindex = frontinitial;
        }
    }
    static if(isBidirectional){
        this(Range source, size_t frontinitial, size_t backinitial){
            this.source = source;
            this.frontindex = frontinitial;
            this.backindex = backinitial;
        }
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return Element(this.frontindex, this.source.front);
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
        this.frontindex++;
    }
    
    static if(isBidirectional){
        @property auto ref back() in{assert(!this.empty);} body{
            return Element(this.backindex, this.source.back);
        }
        void popBack() in{assert(!this.empty);} body{
            this.source.popBack();
            this.backindex--;
        }
    }
    
    static if(isRandomAccessRange!Range){
        auto ref opIndex(size_t index){
            return Element(index, this.source[index]);
        }
    }
    
    static if(isSlicingRange!Range){
        auto ref opSlice(size_t low, size_t high){
            static if(isBidirectional){
                return typeof(this)(this.source[low .. high], low, high);
            }else{
                return typeof(this)(this.source[low .. high], low);
            }
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            static if(isBidirectional){
                return typeof(this)(this.source.save, this.frontindex, this.backindex);
            }else{
                return typeof(this)(this.source.save, this.frontindex);
            }
        }
    }
        
    enum bool mutable = isMutableRange!Range;
    
    static if(isMutableFrontRange!Range){
        @property void front(ElementType!Range value){
            this.source.front = value;
        }
    }
    static if(isMutableBackRange!Range){
        @property void back(ElementType!Range value){
            this.source.back = value;
        }
    }
    static if(isMutableRandomRange!Range){
        void opIndexAssign(ElementType!Range value, size_t index){
            this.source[index] = value;
        }
    }
    static if(isMutableInsertRange!Range){
        void insert(ElementType!Range value){
            this.source.insert(value);
        }
    }
    static if(isMutableRemoveFrontRange!Range){
        void removeFront(){
            this.source.removeFront();
            this.frontindex++;
        }
    }
    static if(isBidirectional && isMutableRemoveBackRange!Range){
        void removeBack(){
            this.source.removeBack();
            this.backindex++;
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.pluck : pluck;
    import mach.range.repeat : repeat;
    import mach.collect : DoublyLinkedList;
}
unittest{
    tests("Enumerate", {
        tests("Bidirectionality", {
            auto range = "hello".enumerate;
            testf(range.empty);
            testeq(range.length, 5);
            testeq(range.remaining, 5);
            testeq(range.front.index, 0);
            testeq(range.front.value, 'h');
            testeq(range.back.index, 4);
            testeq(range.back.value, 'o');
            range.popFront();
            testeq(range.length, 5);
            testeq(range.remaining, 4);
            testeq(range.front.index, 1);
            testeq(range.front.value, 'e');
            range.popBack();
            testeq(range.remaining, 3);
            testeq(range.back.index, 3);
            testeq(range.back.value, 'l');
            range.popFront();
            testeq(range.remaining, 2);
            testeq(range.front.index, 2);
            testeq(range.front.value, 'l');
            range.popBack();
            testeq(range.remaining, 1);
            testeq(range.back.index, 2);
            testeq(range.back.value, 'l');
            range.popFront();
            testeq(range.remaining, 0);
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront();});
            testfail({range.back;});
            testfail({range.popBack();});
        });
        tests("Foreach", {
            foreach(index, value; [1, 2, 3].enumerate){
                testeq(index + 1, value);
            }
            foreach_reverse(index, value; [1, 2, 3].enumerate){
                testeq(index + 1, value);
            }
        });
        tests("Random access", {
            auto range = "hello".enumerate;
            testeq(range[0].index, 0);
            testeq(range[0].value, 'h');
            testeq(range[$-1].index, 4);
            testeq(range[$-1].value, 'o');
            testfail({range[$];});
        });
        tests("Slicing", {
            auto range = "abc".enumerate;
            test(range[0 .. 0].empty);
            test(range[$ .. $].empty);
            test!equals(range[0 .. 1].pluck!`index`, [0]);
            test!equals(range[0 .. 1].pluck!`value`, "a");
            test!equals(range[0 .. 2].pluck!`index`, [0, 1]);
            test!equals(range[0 .. 2].pluck!`value`, "ab");
            test!equals(range[0 .. $].pluck!`index`, [0, 1, 2]);
            test!equals(range[0 .. $].pluck!`value`, "abc");
            test!equals(range[1 .. $].pluck!`index`, [1, 2]);
            test!equals(range[1 .. $].pluck!`value`, "bc");
            test!equals(range[2 .. $].pluck!`index`, [2]);
            test!equals(range[2 .. $].pluck!`value`, "c");
            testfail({range[0 .. $+1];});
        });
        tests("Mutability", {
            char[] input = ['a', 'b', 'c'];
            auto range = input.enumerate;
            range.front = 'x';
            testeq(input[0], 'x');
            range.back = 'y';
            testeq(input[$-1], 'y');
            range[1] = 'z';
            testeq(input[1], 'z');
        });
        tests("Removal", {
            auto list = new DoublyLinkedList!int([0, 1, 2, 3]);
            auto range = list.enumerate;
            testeq(range.front.index, 0);
            testeq(range.front.value, 0);
            range.removeFront();
            testeq(range.front.index, 1);
            testeq(range.front.value, 1);
            test!equals(list.ivalues, [1, 2, 3]);
        });
        tests("Static array", {
            int[5] ints = [0, 1, 2, 3, 4];
            foreach(x, y; ints.enumerate){
                testeq(x, y);
            }
        });
        tests("Immutable source", {
            const(const(int)[]) ints = [0, 1, 2, 3, 4];
            foreach(x, y; ints.enumerate){
                testeq(x, y);
            }
        });
        tests("Infinite source", {
            auto range = "abc".repeat.enumerate;
            static assert(!is(typeof(range.back)));
            testeq(range.front.index, 0);
            testeq(range.front.value, 'a');
            range.popFront();
            testeq(range.front.index, 1);
            testeq(range.front.value, 'b');
            range.popFront();
            testeq(range.front.index, 2);
            testeq(range.front.value, 'c');
            range.popFront();
            testeq(range.front.index, 3);
            testeq(range.front.value, 'a');
        });
    });
}
