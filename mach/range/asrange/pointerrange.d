module mach.range.asrange.pointerrange;

private:

import mach.traits : isPointer;
import mach.error : IndexOutOfBoundsError, InvalidSliceBoundsError;

/++ Docs

The `aspointerrange` function can be used to create a range which enumerates
over elements pointed at by a given pointer.
It accepts an optional length argument; when this argument is absent the
returned range is infinite and, when it is present, the range is finite and
of the length specified.

A `FinitePointerRange`, returned when a length argument is included, is saving
and bidirectional, and supports random access and slicing.
When the value pointed to by the pointer used to create the range is mutable,
so does the range allow mutation of front, back, and randomly-accessed elements.

An `InfinitePointerRange` range, returned when no length argument is included,
allows saving and random access, and when sliced returns a `FinitePointerRange`.
When the value pointed to by the pointer used to create the range is mutable,
so does the range allow mutation of front and randomly-accessed elements.

+/

unittest{ /// Example
    // Example of a finite pointer range
    string str = "hello";
    auto range = str.ptr.aspointerrange(str.length);
    assert(range.front == 'h');
    assert(range.back == 'o');
}

unittest{ /// Example
    // Example of an infinite pointer range
    string str = "world";
    auto range = str.ptr.aspointerrange();
    assert(range.front == 'w');
    static assert(!range.empty);
}

public:



/// Given a pointer, get a range for enumerating the elements it points to
/// infinitely.
auto aspointerrange(T)(T ptr) if(isPointer!T){
    return InfinitePointerRange!T(ptr);
}

/// Given a pointer, get a range enumerating the given number of elements
/// beginning at that pointer.
auto aspointerrange(T)(T ptr, in size_t length) if(isPointer!T){
    return FinitePointerRange!T(ptr, length);
}



/// A range for infinitely enumerating elements located at a pointer.
struct InfinitePointerRange(T) if(isPointer!T){
    enum bool mutable = is(typeof({*this.ptr = *this.ptr;}));
    enum bool empty = false;
    
    T ptr;
    size_t index = 0;
    
    @property auto consumedFront() const{
        return this.index;
    }
    alias consumed = consumedFront;
    
    @property auto ref front(){
        return this.ptr[this.index];
    }
    void popFront(){
        this.index++;
    }
    
    auto ref opIndex(in size_t index){
        return this.ptr[index];
    }
    auto ref opSlice(in size_t low, in size_t high){
        return FinitePointerRange!T(this.ptr + low, high - low);
    }
    
    @property typeof(this) save(){
        return this;
    }
}



/// A range for enumerating elements located at a pointer, with a finite length.
struct FinitePointerRange(T) if(isPointer!T){
    enum bool mutable = is(typeof({*this.ptr = *this.ptr;}));
    
    T ptr;
    size_t frontindex;
    size_t backindex;
    size_t memlength;
    
    this(T ptr, size_t length){
        this(ptr, 0, length, length);
    }
    this(T ptr, size_t frontindex, size_t backindex, size_t memlength){
        this.ptr = ptr;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.memlength = memlength;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto length() const{
        return this.memlength;
    }
    @property auto remaining() const{
        return this.backindex - this.frontindex;
    }
    @property auto consumed() const{
        return this.length - this.remaining;
    }
    @property auto consumedFront() const{
        return this.frontindex;
    }
    @property auto consumedBack() const{
        return this.memlength - this.backindex;
    }
    alias opDollar = length;
    
    @property auto ref front() in{assert(!this.empty);} body{
        return this.ptr[this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    
    @property auto ref back() in{assert(!this.empty);} body{
        return this.ptr[this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    auto ref opIndex(in size_t index) in{
        static const error = new IndexOutOfBoundsError();
        error.enforce(index, this);
    }body{
        return this.ptr[index];
    }
    auto ref opSlice(in size_t low, in size_t high) in{
        static const error = new InvalidSliceBoundsError();
        error.enforce(low, high, this);
    }body{
        return typeof(this)(this.ptr + low, high - low);
    }
    
    @property typeof(this) save(){
        return this;
    }
}



private version(unittest){
    import mach.test;
    import mach.traits : isInfiniteRange, isMutableRange;
    import mach.range.compare : equals;
}

unittest{
    tests("Pointer range", {
        tests("Infinite", {
            static assert(isInfiniteRange!(typeof((int*).init.aspointerrange)));
            static assert(isMutableRange!(typeof((int*).init.aspointerrange)));
            static assert(!isMutableRange!(typeof((const(int)*).init.aspointerrange)));
            tests("Iteration", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange;
                testeq(range.front, 0);
                testeq(range.consumed, 0);
                range.popFront();
                testeq(range.front, 1);
                testeq(range.consumed, 1);
            });
            tests("Slicing", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange;
                test(range[0 .. 0].empty);
                test(range[100 .. 100].empty);
                test!equals(range[0 .. 3], [0, 1, 2]);
                test!equals(range[3 .. 6], [3, 4, 5]);
                test!equals(range[0 .. 6], [0, 1, 2, 3, 4, 5]);
            });
            tests("Saving", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange;
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 1);
                testeq(saved.front, 0);
            });
            tests("Mutation", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange;
                range.front = 10;
                testeq(range.front, 10);
                testeq(ints, [10, 1, 2, 3, 4, 5]);
                testeq(range[2], 2);
                range[2] = 20;
                testeq(range[2], 20);
                testeq(ints, [10, 1, 20, 3, 4, 5]);
            });
        });
        tests("Finite", {
            static assert(isMutableRange!(typeof((int*).init.aspointerrange(0))));
            static assert(!isMutableRange!(typeof((const(int)*).init.aspointerrange(0))));
            tests("Iteration", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange(ints.length);
                testf(range.empty);
                testeq(range.length, 6);
                testeq(range.remaining, 6);
                testeq(range.consumed, 0);
                testeq(range.consumedFront, 0);
                testeq(range.consumedBack, 0);
                testeq(range.front, 0);
                testeq(range.back, 5);
                range.popFront();
                testeq(range.front, 1);
                testeq(range.length, 6);
                testeq(range.remaining, 5);
                testeq(range.consumed, 1);
                testeq(range.consumedFront, 1);
                testeq(range.consumedBack, 0);
                range.popBack();
                testeq(range.back, 4);
                testeq(range.remaining, 4);
                testeq(range.consumed, 2);
                testeq(range.consumedFront, 1);
                testeq(range.consumedBack, 1);
                range.popFront();
                testeq(range.remaining, 3);
                testeq(range.consumed, 3);
                range.popBack();
                testeq(range.remaining, 2);
                testeq(range.consumed, 4);
                range.popFront();
                testeq(range.remaining, 1);
                testeq(range.consumed, 5);
                range.popBack();
                test(range.empty);
                testeq(range.remaining, 0);
                testeq(range.consumed, 6);
                testfail({range.front;});
                testfail({range.popFront;});
                testfail({range.back;});
                testfail({range.popBack;});
            });
            tests("Random access", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange(ints.length);
                testeq(range[0], 0);
                testeq(range[1], 1);
                testeq(range[$-1], 5);
                testfail!IndexOutOfBoundsError({range[$];});
            });
            tests("Slicing", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange(ints.length);
                test(range[0 .. 0].empty);
                test(range[$ .. $].empty);
                test!equals(range[0 .. 3], [0, 1, 2]);
                test!equals(range[3 .. $], [3, 4, 5]);
                test!equals(range[0 .. $], [0, 1, 2, 3, 4, 5]);
                testfail!InvalidSliceBoundsError({range[0 .. $+1];});
            });
            tests("Saving", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange(ints.length);
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 1);
                testeq(saved.front, 0);
            });
            tests("Mutation", {
                auto ints = [0, 1, 2, 3, 4, 5];
                auto range = ints.ptr.aspointerrange(ints.length);
                range.front = 100;
                testeq(range.front, 100);
                testeq(ints, [100, 1, 2, 3, 4, 5]);
                range.back = 50;
                testeq(range.back, 50);
                testeq(ints, [100, 1, 2, 3, 4, 50]);
                range[2] = 20;
                testeq(range[2], 20);
                testeq(ints, [100, 1, 20, 3, 4, 50]);
            });
        });
    });
}
