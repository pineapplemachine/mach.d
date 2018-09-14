module mach.range.repeat;

private:

import mach.types : Rebindable;
import mach.traits : isIterable, isFiniteIterable, isInfiniteIterable;
import mach.traits : isFiniteRange, isRandomAccessRange, isSavingRange;
import mach.traits : isBidirectionalRange, hasNumericLength, hasNumericRemaining;
import mach.range.asrange : asrange, validAsRange;
import mach.range.asrange : validAsRandomAccessRange, validAsSavingRange;
import mach.error : IndexOutOfBoundsError;

/++ Docs

The `repeat` function can be used to repeat an inputted iterable either
infinitely or a specified number of times, depending on whether a limit is
passed to it.

In order for an iterable to repeated either finitely or infinitely, it must be
infinite, have random access and length, or be valid as a saving range.
Repeating an already-infinite iterable returns the selfsame iterable,
regardless of whether the repeating was intended to be finite or infinite.

When `repeat` is called for an iterable without any additional arguments,
that iterable is repeated infinitely.

+/

unittest{ /// Example
    import mach.range.compareends : headis;
    auto range = "hi".repeat;
    assert(range.headis("hihihihihi"));
}

unittest{ /// Example
    // Fun fact: Infinitely repeated ranges are technically bidirectional.
    assert("NICE".repeat.back == 'E');
}

/++ Docs

When the function is called with an additional integer argument, that argument
dictates how many times the input will be repeated before the resulting range
is exhausted.

Finitely repeated ranges support `length` and `remaining` properties when their
inputs support them. They allow random access when the input has random access
and numeric length. All finitely and infinitely repeated ranges allow saving.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    auto range = "yo".repeat(3);
    assert(range.equals("yoyoyo"));
}

/++ Docs

The `repeat` function does not support infinitely repeating an empty iterable,
because attempting to do so would invalidate many of the compile-time checks
made possible by assuming the result of infinitely repeating an input is in
fact an infinite range.
An `InfiniteRepeatEmptyError` is thrown when this operation is attempted,
unless the code has been compiled in release mode, in which case the check is
omitted and a nastier error may occur instead.

+/

unittest{ /// Example
    import mach.test.assertthrows : assertthrows;
    assertthrows!InfiniteRepeatEmptyError({
        "".repeat; // Can't infinitely repeat an empty input.
    });
}

public:



/// Exception thrown when attempting to infinitely repeat an empty input.
class InfiniteRepeatEmptyError: Error{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Cannot infinitely repeat an empty range.", file, line, next);
    }
}



/// Determine if a type can be repeated using length and random access.
enum canRepeatRandomAccess(T) = (
    hasNumericLength!T && is(typeof({
        size_t i = 0; auto e = T.init[i];
    }))
);

/// Determine if a type can be repeated by acquiring a range and repeatedly
/// saving and rebinding the resulting range.
enum canRepeatSaving(T) = (
    isFiniteIterable!T && validAsSavingRange!T
);

/// Determine if a `FiniteRepeatSavingRange` or `InfiniteRepeatSavingRange`
/// may be constructed using the given type.
enum canRepeatSavingRange(Range) = (
    isFiniteRange!Range && isSavingRange!Range
);



/// Infinitely repeat an input.
auto repeat(T)(auto ref T input) if(
    isInfiniteIterable!T ||
    canRepeatRandomAccess!T ||
    canRepeatSaving!T
){
    static if(isInfiniteIterable!T){
        // Logically, repeating an infinite iterable results in the same iterable.
        return iter;
    }else static if(canRepeatRandomAccess!T){
        // Repeat using random access if available.
        return repeatrandomaccess(input);
    }else static if(canRepeatSaving!T){
        // Repeat using a saving range if available.
        return repeatsaving(input);
    }else{
        // Shouldn't happen.
        static assert(false, "Invalid type.");
    }
}

/// Repeat an input a given number of times.
auto repeat(T)(auto ref T input, in size_t count) if(
    isInfiniteIterable!T ||
    canRepeatRandomAccess!T ||
    canRepeatSaving!T
){
    static if(isInfiniteIterable!T){
        // Logically, repeating an infinite iterable results in the same iterable.
        return iter;
    }else static if(canRepeatRandomAccess!T){
        // Repeat using random access if available.
        return repeatrandomaccess(input, count);
    }else static if(canRepeatSaving!T){
        // Repeat using a saving range if available.
        return repeatsaving(input, count);
    }else{
        // Shouldn't happen.
        static assert(false, "Invalid type.");
    }
}



/// Infinitely repeat an input having length and random access.
auto repeatrandomaccess(T)(T iter) if(canRepeatRandomAccess!T){
    auto range = iter.asrange;
    return InfiniteRepeatRandomAccessRange!(typeof(range))(range);
}
/// ditto
auto repeatrandomaccess(T)(auto ref T iter, size_t count) if(canRepeatRandomAccess!T){
    auto range = iter.asrange;
    return FiniteRepeatRandomAccessRange!(typeof(range))(range, count);
}

/// Repeat a saving range.
auto repeatsaving(T)(T iter) if(canRepeatSaving!T){
    auto range = iter.asrange;
    return InfiniteRepeatSavingRange!(typeof(range))(range);
}
/// ditto
auto repeatsaving(T)(auto ref T iter, size_t count) if(canRepeatSaving!T){
    auto range = iter.asrange;
    return FiniteRepeatSavingRange!(typeof(range))(range, count);
}



/// Infinitely repeat an input with random access.
struct InfiniteRepeatRandomAccessRange(Source) if(
    canRepeatRandomAccess!Source
){
    enum bool empty = false;
    
    Source source;
    size_t frontindex;
    size_t backindex;
    
    this(Source source, size_t frontindex = 0){
        this(source, frontindex, source.length);
    }
    this(Source source, size_t frontindex, size_t backindex){
        version(assert){
            static const error = new InfiniteRepeatEmptyError();
            if(source.length == 0) throw error; // Can't repeat an empty input
        }
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property auto front(){
        return this.source[this.frontindex];
    }
    void popFront(){
        this.frontindex = (this.frontindex + 1) % cast(size_t) this.source.length;
    }
    
    @property auto back(){
        return this.source[this.backindex - 1];
    }
    void popBack(){
        this.backindex--;
        if(this.backindex == 0) this.backindex = cast(size_t) this.source.length;
    }
    
    auto opIndex(in size_t index) in{assert(index >= 0);} body{
        return this.source[index % cast(size_t) this.source.length];
    }
    
    @property typeof(this) save(){
        return this;
    }
}



/// Repeat an input with random access a given number of times
struct FiniteRepeatRandomAccessRange(Source) if(
    canRepeatRandomAccess!Source
){
    /// The input being repeated.
    Source source;
    /// Number of times the source range is repeated
    size_t limit;
    /// Number of times the source range has been fully consumed
    size_t count;
    /// Index representing the location of the front cursor.
    size_t frontindex;
    /// Index representing the location of the back cursor.
    size_t backindex;
    
    // TODO: Slicing
    
    this(Source source, size_t limit, size_t frontindex = 0){
        this(source, limit, 0, frontindex, cast(size_t) source.length);
    }
    this(Source source, size_t limit, size_t count, size_t frontindex, size_t backindex){
        this.source = source;
        this.limit = limit;
        this.count = count;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    /// Determine whether the range is empty.
    @property bool empty(){
        return (
            this.source.length == 0 || this.limit == 0 ||
            this.count >= (this.limit - (this.frontindex >= this.backindex))
        );
    }
    /// Get the length of the range, equivalent to the length of the source
    /// multiplied by the number of times it is being repeated.
    /// May be incorrect due to overflow for especially large inputs or
    /// number of times repeated.
    @property auto length(){
        return this.source.length * this.limit;
    }
    /// Get the number of elements remaining in the range.
    @property auto remaining(){
        return (
            (cast(size_t) this.source.length) * (this.limit - this.count - 1) +
            (this.backindex - this.frontindex)
        );
    }
    
    alias opDollar = length;
    
    /// Get the frontmost element of the range.
    @property auto front() in{assert(!this.empty);} body{
        return this.source[this.frontindex];
    }
    /// Pop the frontmost element of the range.
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
        if(this.frontindex >= this.source.length){
            this.count++;
            this.frontindex = 0;
        }
    }
    
    /// Get the backmost element of the range.
    @property auto back() in{assert(!this.empty);} body{
        return this.source[this.backindex - 1];
    }
    /// Pop the backmost element of the range.
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
        if(this.backindex == 0){
            this.count++;
            this.backindex = cast(size_t) this.source.length;
        }
    }
    
    /// Implement random access.
    auto opIndex(in size_t index) in{
        static const error = new IndexOutOfBoundsError();
        error.enforce(index, this);
    }body{
        return this.source[index % (cast(size_t) this.source.length)];
    }
    
    /// Save the range.
    @property typeof(this) save(){
        return this;
    }
}



/// Infinitely repeat a range with saving.
struct InfiniteRepeatSavingRange(Range) if(canRepeatSavingRange!Range){
    static enum bool isBidirectional = isBidirectionalRange!Range;
    
    static enum bool empty = false;
    
    Range source;
    Rebindable!Range forward = void;
    static if(isBidirectional) Rebindable!Range backward = void;
    
    this(Range source){
        version(assert){
            static const error = new InfiniteRepeatEmptyError();
            if(source.empty) throw error; // Can't repeat an empty input
        }
        this.source = source;
        this.forward = this.source.save;
        static if(isBidirectional) this.backward = this.source.save;
    }
    
    static if(!isBidirectional){
        this(Range source, Rebindable!Range forward){
            version(assert){
                static const error = new InfiniteRepeatEmptyError();
                if(source.empty) throw error; // Can't repeat an empty input
            }
            this.source = source;
            this.forward = forward;
        }
    }else{
        this(Range source, Rebindable!Range forward, Rebindable!Range backward){
            version(assert){
                static const error = new InfiniteRepeatEmptyError();
                if(source.empty) throw error; // Can't repeat an empty input
            }
            this.source = source;
            this.forward = forward;
            this.backward = backward;
        }
    }
    
    @property auto front(){
        return this.forward.front;
    }
    void popFront(){
        this.forward.popFront();
        if(this.forward.empty) this.forward = this.source.save;
    }
    
    static if(isBidirectional){
        @property auto back(){
            return this.backward.back;
        }
        void popBack(){
            this.backward.popBack();
            if(this.backward.empty) this.backward = this.source.save;
        }
    }
    
    static if(isRandomAccessRange!Range && hasNumericLength!Range){
        auto opIndex(in size_t index){
            return this.source[cast(size_t)(index % this.source.length)];
        }
    }
    
    @property typeof(this) save(){
        static if(!isBidirectional){
            return typeof(this)(this.source, this.forward.save);
        }else{
            return typeof(this)(this.source, this.forward.save, this.backward.save);
        }
    }
}

/// Repeat a range with saving a given number of times.
struct FiniteRepeatSavingRange(Range) if(
    canRepeatSavingRange!Range
){
    Range source;
    Rebindable!Range forward = void;
    
    size_t count; /// Cycle iteration is currently on
    size_t limit; /// Maximum number of cycles before emptiness
    
    // TODO: Bidirectionality
    
    this(Range source, size_t limit){
        this(source, 0, limit);
    }
    this(Range source, size_t count, size_t limit){
        this(source, source.save, count, limit);
    }
    this(Range source, Range forward, size_t count, size_t limit){
        this.count = count;
        this.limit = limit;
        this.source = source;
        this.forward = forward;
    }
    
    @property bool empty(){
        return this.source.empty || this.count >= this.limit;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.forward.front;
    }
    void popFront() in{assert(!this.empty);} body{
        this.forward.popFront();
        if(this.forward.empty){
            this.forward = this.source.save;
            this.count++;
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.source, this.forward.save, this.count, this.limit);
    }
    
    static if(hasNumericLength!Range){
        /// Get the length of the range.
        @property auto length(){
            return this.source.length * limit;
        }
        /// ditto
        alias opDollar = length;
        static if(hasNumericRemaining!Range){
            /// Get the number of elements remaining in the range.
            @property auto remaining(){
                return limit == 0 ? 0 : cast(size_t)(
                    (limit - count - 1) * this.source.length + this.forward.remaining
                );
            }
        }
    }
    
    static if(isRandomAccessRange!Range && hasNumericLength!Range){
        auto opIndex(in size_t index) in{
            static const error = new IndexOutOfBoundsError();
            error.enforce(index, this);
        }body{
            return this.source[cast(size_t)(index % this.source.length)];
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.traits : isInfiniteRange;
    import mach.range.compare : equals;
    
    /// Helper for testing finite repeat ranges.
    void FiniteRepeatTests(alias func)(){
        tests("Empty", {
            tests("Empty input", {
                auto range = func(new int[0], 1);
                testeq(range.length, 0);
                testeq(range.remaining, 0);
                test(range.empty);
            });
            tests("No repetition", {
                auto range = func([1, 2, 3], 0);
                testeq(range.length, 0);
                testeq(range.remaining, 0);
                test(range.empty);
            });
            tests("Both", {
                auto range = func(new int[0], 0);
                testeq(range.length, 0);
                testeq(range.remaining, 0);
                test(range.empty);
            });
        });
        tests("Random access", {
            auto range = func([0, 1, 2], 3);
            testeq(range[0], 0);
            testeq(range[1], 1);
            testeq(range[2], 2);
            testeq(range[3], 0);
            testeq(range[$-1], 2);
        });
        tests("Length & Remaining", {
            foreach(int[] array; [[], [0], [0, 1], [0, 1, 2]]){
                foreach(int i; 0 .. 10){
                    auto range = func(array, i);
                    testeq(range.length, array.length * i);
                    size_t count = cast(size_t) range.remaining;
                    testeq(count, array.length * i);
                    while(count > 0){
                        range.popFront();
                        count--;
                        testeq(range.remaining, count);
                    }
                }
            }
        });
        tests("Saving", {
            auto a = func([1, 2, 3], 2);
            auto b = a.save;
            a.popFront();
            testeq(a.front, 2);
            testeq(b.front, 1);
        });
        tests("Equality", {
            int[] empty = new int[0];
            test!equals(func(empty, 0), empty);
            test!equals(func(empty, 1), empty);
            test!equals(func(empty, 2), empty);
            test!equals(func([1], 0), empty);
            test!equals(func([1], 1), [1]);
            test!equals(func([1], 2), [1, 1]);
            test!equals(func([1], 4), [1, 1, 1, 1]);
            test!equals(func([1, 2], 0), empty);
            test!equals(func([1, 2], 1), [1, 2]);
            test!equals(func([1, 2], 2), [1, 2, 1, 2]);
            test!equals(func([1, 2], 3), [1, 2, 1, 2, 1, 2]);
        });
        static if(isBidirectionalRange!(typeof(func([0], 0)))){
            tests("Bidirectionality & Remaining", {
                auto range = func([1, 2, 3], 3);
                testeq(range.length, 9);
                testeq(range.remaining, 9);
                testeq(range.front, 1);
                testeq(range.back, 3);
                range.popFront();
                testeq(range.remaining, 8);
                testeq(range.front, 2);
                range.popBack();
                testeq(range.remaining, 7);
                testeq(range.back, 2);
                range.popBack();
                testeq(range.remaining, 6);
                testeq(range.back, 1);
                range.popBack();
                testeq(range.remaining, 5);
                testeq(range.back, 3);
                range.popBack();
                testeq(range.remaining, 4);
                testeq(range.back, 2);
                range.popBack();
                testeq(range.remaining, 3);
                testeq(range.back, 1);
                range.popBack();
                testeq(range.remaining, 2);
                testeq(range.back, 3);
                range.popBack();
                testeq(range.remaining, 1);
                testeq(range.back, 2);
                range.popBack();
                testeq(range.length, 9);
                testeq(range.remaining, 0);
                test(range.empty);
                testfail({range.front;});
                testfail({range.popFront();});
                testfail({range.back;});
                testfail({range.popBack();});
            });
        }
    }
    
    /// Helper for testing infinite repeat ranges.
    void InfiniteRepeatTests(alias func)(){
        static assert(isInfiniteRange!(typeof([0].repeatsaving)));
        tests("Empty input", {
            // Can't infinitely repeat an empty input
            // Well, technically you could, but it would screw up the logic that
            // indicates the repeat range is infinite.
            testfail({func(new int[0]);});
        });
        tests("Single-length input", {
            auto range = func([0]);
            testf(range.empty);
            testeq(range.front, 0);
            testeq(range.back, 0);
            testeq(range[0], 0);
            testeq(range[10000], 0);
            range.popFront();
            range.popBack();
            testeq(range.front, 0);
            testeq(range.back, 0);
        });
        tests("Random access", {
            auto range = func([0, 1, 2]);
            testeq(range[0], 0);
            testeq(range[1], 1);
            testeq(range[2], 2);
            testeq(range[3], 0);
        });
        tests("Saving", {
            auto a = func([1, 2, 3]);
            auto b = a.save;
            a.popFront();
            testeq(a.front, 2);
            testeq(b.front, 1);
        });
        tests("Bidirectionality", {
            auto range = func([0, 1, 2]);
            testeq(range.front, 0);
            testeq(range.back, 2);
            range.popFront();
            testeq(range.front, 1);
            range.popBack();
            testeq(range.back, 1);
            range.popFront();
            testeq(range.front, 2);
            range.popBack();
            testeq(range.back, 0);
        });
    }
}

unittest{
    tests("Repeat", {
        tests("Saving", {
            tests("Finitely", {
                FiniteRepeatTests!repeatsaving;
            });
            tests("Infinitely", {
                InfiniteRepeatTests!repeatsaving;
            });
        });
        tests("Random access", {
            tests("Finitely", {
                FiniteRepeatTests!repeatrandomaccess;
            });
            tests("Infinitely", {
                InfiniteRepeatTests!repeatsaving;
            });
        });
    });
}
