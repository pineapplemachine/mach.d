module mach.range.walk;

private:

import mach.traits : isIterable, isFiniteIterable;
import mach.traits : isRange, isSavingRange, ElementType;
import mach.error : IndexOutOfBoundsError, InvalidSliceBoundsError;
import mach.range.asrange : asrange, validAsRange;
import mach.range.ends : SimpleHeadRange;

/++ Docs

This module implements `walklength`, `walkindex`, and `walkslice` functions
which acquire the number of elements in an iterable, the element at an index,
and a slice of elements, respectively, by actually traversing the input.
These functions are useful for determining these properties even for ranges
which do not support them because no more efficient implementation than
traversal would be available.

When the input of `walkslice` is valid as a range, it will itself return a
range to lazily enumerate the elements of the slice.
When the input is not valid as a range, the slice will be accumulated in-memory
in an array and returned.

+/

unittest{ /// Example
    import mach.range.recur : recur;
    import mach.range.compare : equals;
    auto range = 0.recur!(n => n + 1, n => n >= 10); // Enumerate numbers 0 through 10.
    assert(range.walklength == 10);
    assert(range.walkindex(4) == 4);
    assert(range.walkslice(2, 4).equals([2, 3]));
}

/++ Docs

The `walkindex` and `walkslice` functions will produce errors if the passed
indexes are out of bounds.
(In release mode, some of these checks necessary to helpfully report errors are
omitted and nastier errors may occur instead.)
These errors can be circumvented by providing a fallback value to `walkindex`
and `walkslice`, where if the indexes being acquired exceed the length of the
input, the fallback is returned for the missing elements instead.

+/

unittest{ /// Example
    import mach.test.assertthrows : assertthrows;
    import mach.range.consume : consume;
    assertthrows({
        "hello".walkindex(100);
    });
    assertthrows({
        // The error is thrown upon the invalid index being encountered,
        // not upon creation of the `walkslice` range.
        "hello".walkslice(0, 100).consume;
    });
}

unittest{ /// Example
    // A fallback can be used to compensate for out-of-bounds indexes.
    import mach.range.compare : equals;
    assert("hi".walkindex(10, '_') == '_');
    assert("hello".walkslice(3, 8, '_').equals("lo___"));
}

public:



enum canWalkLength(T) = isFiniteIterable!T;

enum canWalkIndex(T) = isIterable!T;

enum canWalkSlice(T) = isIterable!T;



/// Determine number of elements of an iterable by traversing it.
auto walklength(Iter)(auto ref Iter iter) if(canWalkLength!Iter){
    size_t length = 0;
    foreach(item; iter) length++;
    return length;
}



/// Get the value at an index of some iterable by traversing it.
auto walkindex(Iter)(auto ref Iter iter, in size_t index) if(canWalkIndex!Iter){
    size_t i = 0;
    foreach(item; iter){
        if(i >= index) return item;
        i++;
    }
    static const error = new IndexOutOfBoundsError();
    throw error;
}

/// ditto
auto walkindex(Iter, T)(auto ref Iter iter, in size_t index, auto ref T fallback) if(
    canWalkIndex!Iter && is(typeof({ElementType!Iter[] x = [fallback];}))
){
    size_t i = 0;
    foreach(item; iter){
        if(i >= index) return item;
        i++;
    }
    return fallback;
}



/// Get a slice from some iterable by traversing it.
auto walkslice(Iter)(auto ref Iter iter, in size_t low, in size_t high) if(
    canWalkSlice!Iter
){
    version(assert){
        static const error = new InvalidSliceBoundsError();
        if(low > high) throw error;
    }
    static if(validAsRange!Iter){
        auto range = iter.asrange;
        return WalkSliceRange!(typeof(range), false)(range, low, high);
    }else{
        ElementType!Iter slice;
        slice.reserve(high - low);
        size_t i = 0;
        foreach(item; iter){
            if(i > high) break;
            else if(i >= low) slice ~= item;
            i++;
        }
        version(assert){
            if(slice.length != high - low) throw error;
        }
        return slice;
    }
}

/// ditto
auto walkslice(Iter, T)(auto ref Iter iter, in size_t low, in size_t high, auto ref T fallback) if(
    canWalkSlice!Iter && is(typeof({ElementType!Iter[] x = [fallback];}))
)in{
    static const error = new InvalidSliceBoundsError();
    if(low > high) throw error;
}body{
    static if(validAsRange!Iter){
        auto range = iter.asrange;
        return WalkSliceRange!(typeof(range), true)(range, low, high, fallback);
    }else{
        ElementType!Iter slice;
        slice.reserve(high - low);
        size_t i = 0;
        foreach(item; iter){
            if(i > high) break;
            else if(i >= low) slice ~= item;
            i++;
        }
        while(slice.length < (high - low)) slice ~= fallback;
        return slice;
    }
}



struct WalkSliceRange(Range, bool hasfallback) if(isRange!Range){
    alias Element = ElementType!Range;
    
    Range source;
    size_t low;
    size_t high;
    size_t index = 0;
    static if(hasfallback) Element fallback;
    
    static if(hasfallback){
        this(Range source, size_t low, size_t high, Element fallback){
            this(source, low, high, 0, fallback);
            this.prepareFront();
        }
        this(Range source, size_t low, size_t high, size_t index, Element fallback){
            this.source = source;
            this.low = low;
            this.high = high;
            this.index = index;
            this.fallback = fallback;
        }
    }else{
        this(Range source, size_t low, size_t high){
            this(source, low, high, 0);
            this.prepareFront();
        }
        this(Range source, size_t low, size_t high, size_t index){
            this.source = source;
            this.low = low;
            this.high = high;
            this.index = index;
        }
    }
    
    @property auto length() const{
        return this.high - this.low;
    }
    alias opDollar = length;
    
    @property auto remaining() const{
        return this.index >= this.low ? this.high - this.index : this.length;
    }
    
    @property bool empty() const{
        return this.low == this.high || this.index >= this.high;
    }
    @property auto front() in{assert(!this.empty);} body{
        static if(!hasfallback){
            return this.source.front;
        }else{
            return this.source.empty ? this.fallback : this.source.front;
        }
    }
    void popFront() in{assert(!this.empty);} body{
        static if(!hasfallback){
            version(assert){
                static const error = new InvalidSliceBoundsError();
                if(this.source.empty) throw error;
            }
            this.source.popFront();
        }else{
            if(!this.source.empty) this.source.popFront();
        }
        this.index++;
    }
    
    void prepareFront(){
        static if(hasfallback){
            if(this.low == this.high) return;
        }
        while(this.index < this.low){
            static if(!hasfallback){
                version(assert){
                    static const error = new InvalidSliceBoundsError();
                    if(this.source.empty) throw error;
                }
                this.source.popFront();
            }else{
                if(this.source.empty){
                    this.index = this.low;
                    return;
                }else{
                    this.source.popFront();
                }
            }
            this.index++;
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            static if(!hasfallback){
                return typeof(this)(source.save, this.low, this.high, this.index);
            }else{
                return typeof(this)(source.save, this.low, this.high, this.index, this.fallback);
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
    import mach.io.log;
}
unittest{
    tests("Walk", {
        tests("Length", {
            testeq("".walklength, 0);
            testeq("hi".walklength, 2);
            testeq("hello".walklength, 5);
            testeq("".asrange.walklength, 0);
            testeq("hi".asrange.walklength, 2);
            testeq("hello".asrange.walklength, 5);
        });
        tests("Index", {
            tests("No fallback", {
                testeq("hi".walkindex(0), 'h');
                testeq("hi".walkindex(1), 'i');
                testfail({"hi".walkindex(2);});
                testfail({"".walkindex(0);});
            });
            tests("With fallback", {
                testeq("hi".walkindex(0, '_'), 'h');
                testeq("hi".walkindex(1, '_'), 'i');
                testeq("hi".walkindex(2, '_'), '_');
                testeq("hi".walkindex(3, '_'), '_');
            });
        });
        tests("Slice", {
            tests("No fallback", {
                testeq("hi".walkslice(0, 2).length, 2);
                test("hi".walkslice(0, 2).equals("hi"));
                test("hi".walkslice(0, 1).equals("h"));
                test("hi".walkslice(1, 2).equals("i"));
                test("hi".walkslice(0, 0).equals(""));
                test("hi".walkslice(1, 1).equals(""));
                test("hi".walkslice(2, 2).equals(""));
                test("".walkslice(0, 0).equals(""));
                testfail({"hi".walkslice(0, 3).consume;});
                testfail({"".walkslice(0, 1).consume;});
            });
            tests("With fallback", {
                testeq("hi".walkslice(0, 2, '_').length, 2);
                test("hi".walkslice(0, 2, '_').equals("hi"));
                test("hi".walkslice(0, 1, '_').equals("h"));
                test("hi".walkslice(1, 2, '_').equals("i"));
                test("hi".walkslice(0, 0, '_').equals(""));
                test("hi".walkslice(1, 1, '_').equals(""));
                test("hi".walkslice(2, 2, '_').equals(""));
                test("hi".walkslice(3, 3, '_').equals(""));
                test("hi".walkslice(0, 3, '_').equals("hi_"));
                test("hi".walkslice(0, 4, '_').equals("hi__"));
                test("hi".walkslice(2, 4, '_').equals("__"));
            });
        });
        tests("Combination", {
            testeq("hello".walkslice(0, 2).walklength, 2);
            testeq("hello".walkslice(0, 2).walkindex(1), 'e');
            testeq("hello".walkslice(2, 5).walkindex(2), 'o');
        });
    });
}
