module mach.math.numrange;

private:

import mach.meta : varmin, varmax;
import mach.traits : isNumeric, isIntegral, isSigned;
import mach.error : IndexOutOfBoundsError, InvalidSliceBoundsError;
import mach.math.round : divceil;

/++ Docs

The `NumberRange` type represents some range of numbers spanning an inclusive
lower bound and an exclusive higher bound.
The `numrange` function can be used for convenience to acquire a `NumberRange`
from arguments without having to explicitly specify their type.

+/

unittest{ /// Example
    auto range = numrange(0, 10);
    assert(range.low == 0);
    assert(range.high == 10);
}

/++ Docs

Ranges are not required to be normalized, and may have their low bound be
greater than their high bound.
In cases like this, the `lower` and `higher` methods can be used to reliably
acquire the actually lower and higher bounds.

+/

unittest{ /// Example
    auto range = numrange(10, 0);
    assert(range.low == 10);
    assert(range.high == 0);
    assert(range.lower == 0);
    assert(range.higher == 10);
    assert(range.alignment is range.Alignment.Inverted);
}

/++ Docs

The `NumberRange` type implements a `length` method to get the positive
difference between its low and high bounds and a `delta` method to get a signed
difference of `high - low`.
Its `overlaps` method can be used to determine whether one range overlaps
another and `contains` used to determine whether one range entirely contains
another.
`contains` also accepts a number, and determines whether that number is within
the range's bounds.

The `contains` method is alternatively accessible via the `in` operator.

+/

unittest{ /// Example
    auto range = numrange(10, 15);
    assert(range.delta == 5);
    assert(range.length == 5);
    assert(range.overlaps(numrange(0, 20)));
    assert(numrange(11, 12) in range);
    assert(13 in range);
    assert(200 !in range);
}

/++ Docs

A range (as in, an iterable type) can be acquired from a `NumberRange` via
its `asrange` method.
Ranges constructed from integral types allow `asrange` to be called without
arguments, and the produced range enumerates the integers in the `NumberRange`.
In all cases a step may be provided, and for non-integral types is not optional,
determining what the difference between enumerated values should be.
The first value of a range produced via `asrange` will always be the lower bound
of the `NumberRange` and the last value will always be less than the higher
bound.

Note that a range produced from a `NumberRange` will always progress from
lesser to greater numbers, regardless of whether the `NumberRange` was normal
or inverted.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    assert(numrange(0, 8).asrange.equals([0, 1, 2, 3, 4, 5, 6, 7])); // Implicit step
    assert(numrange(0, 8).asrange(3).equals([0, 3, 6])); // Explicit step
}

public:



/// Get a `NumberRange` with the given low and high bounds.
auto numrange(T)(in T low, in T high) if(isNumeric!T){
    return NumberRange!T(low, high);
}



/// A `NumberRange` where `low <= high` is considered to have a normal alignment.
/// Otherwise, it has an inverted alignment.
enum NumberRangeAlignment{
    Normal, Inverted
}

/// Type representing a range of numbers in between some lower bound (inclusive)
/// and higher bound (exclusive).
struct NumberRange(T) if(isNumeric!T){
    alias Alignment = NumberRangeAlignment;
    
    T low;
    T high;
    
    /// True when `high == low`.
    @property bool empty() const{
        return this.low == this.high;
    }
    /// Get `high - low`.
    @property auto delta() const{
        return this.high - this.low;
    }
    /// Get the non-negative difference of `high` and `low`.
    @property auto length() const{
        return this.high >= this.low ? this.high - this.low : this.low - this.high;
    }
    alias opDollar = length;
    
    /// Returns `Alignment.Normal` when `low` <= `high`.
    /// Returns `Alignment.Inverted` when `low` > `high`.
    @property auto alignment() const{
        return this.low <= this.high ? Alignment.Normal : Alignment.Inverted;
    }
    
    /// Get whichever value is lesser out of `high` and `low`.
    @property auto lower() const{
        return varmin(this.high, this.low);
    }
    /// Get whichever value is greater out of `high` and `low`.
    @property auto higher() const{
        return varmax(this.high, this.low);
    }
    
    /// Determine whether two ranges overlap.
    @property bool overlaps(X)(in NumberRange!X range) const{
        return this.lower <= range.higher && range.lower <= this.higher;
    }
    /// Determine whether this range entirely contains the values of another.
    /// An empty range contains itself.
    @property bool contains(X)(in NumberRange!X range) const{
        return range.lower >= this.lower && range.higher <= this.higher;
    }
    /// Determine whether a value is between `low` and `high`.
    /// The lower bound is inclusive and the higher bound is exclusive.
    @property bool contains(X)(in X value) const if(isNumeric!X){
        // TODO: This and some other similar methods may give bad results
        // when mixing signed and unsigned integers.
        return value >= this.lower && value < this.higher;
    }
    
    /// Get a range for enumerating values in this number range,
    /// where each value is the previous value + `step`.
    /// The first value is `high` or `low`, whichever is lesser,
    /// and the last value is less than `high` or `low`,
    /// whichever is greater.
    @property auto asrange(in T step) const{
        return NumberRangeRange!T(this, step);
    }
    /// Same as `asrange` with a step argument, except that with integer
    /// types the step defaults to 1 if not specified.
    static if(isIntegral!T) @property auto asrange() const{
        return NumberRangeRange!T(this, T(1));
    }
    
    /// Determine whether two ranges are equal.
    /// Ranges with equal but swapped high and low bounds are considered equal.
    bool opEquals(X)(in NumberRange!X range) const{
        return this.lower == range.lower && this.higher == range.higher;
    }
    
    /// Order ranges by their lower bound first and their higher bound second.
    /// Ranges with lesser lower bounds precede ranges with higher lower bounds,
    /// and when lower bounds are equal ranges with lesser higher bounds
    /// precede those with greater higher bounds.
    int opCmp(X)(in NumberRange!X range) const{
        if(this.lower < range.lower){
            return -1;
        }else if(this.lower > range.lower){
            return 1;
        }else if(this.higher < range.higher){
            return -1;
        }else if(this.higher > range.higher){
            return 1;
        }else{
            return 0;
        }
    }
    
    bool opBinaryRight(string op: "in", X)(in NumberRange!X range) const{
        return this.contains(range);
    }
    bool opBinaryRight(string op: "in", X)(in X value) const if(isNumeric!X){
        return this.contains(value);
    }
    
    auto opBinary(string op: "+")(in T value) const{
        return typeof(this)(this.lower + value, this.higher + value);
    }
    auto opBinary(string op: "-")(in T value) const{
        return typeof(this)(this.lower - value, this.higher - value);
    }
    
    auto opOpAssign(string op: "+")(in T value){
        this.low += value;
        this.high += value;
        return this;
    }
    auto opOpAssign(string op: "-")(in T value){
        this.low -= value;
        this.high -= value;
        return this;
    }
}



/// Range type for enumerating values in a number range.
struct NumberRangeRange(T) if(isNumeric!T){
    alias Source = NumberRange!T;
    
    Source source;
    T step;
    size_t frontindex;
    size_t backindex;
    
    this(Source source, T step){
        this(source, step, 0, divceil(source.length, step));
    }
    this(Source source, T step, size_t frontindex, size_t backindex) in{
        assert(step > 0);
    }body{
        this.source = source;
        this.step = step;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property size_t remaining() const{
        return this.backindex - this.frontindex;
    }
    @property size_t length() const{
        return cast(size_t)(this.source.length / step);
    }
    alias opDollar = length;
    
    @property auto front() const in{assert(!this.empty);} body{
        return this.source.lower + this.step * this.frontindex;
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    @property auto back() const in{assert(!this.empty);} body{
        return this.source.lower + this.step * (this.backindex - 1);
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    auto opIndex(in size_t index) const in{
        static const error = new IndexOutOfBoundsError();
        error.enforce(index, this);
    }body{
        return this.source.lower + this.step * index;
    }
    
    typeof(this) opSlice(in size_t low, in size_t high) in{
        static const error = new InvalidSliceBoundsError();
        error.enforce(low, high, this);
    }body{
        return typeof(this)(Source(
            cast(T)(this.source.lower + this.step * low),
            cast(T)(this.source.lower + this.step * high)
        ), this.step);
    }
    
    @property typeof(this) save(){
        return this;
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.error.mustthrow : mustthrow;
    import mach.range.compare : equals;
    import mach.sort : issorted;
}

unittest{ /// Empty ranges
    foreach(T; Aliases!(int, uint, long, ulong, float, double, real)){
        foreach(n; [T(0), T(1), T(100)]){
            auto range = numrange(n, n);
            assert(range.empty);
            assert(range.low == n);
            assert(range.high == n);
            assert(range.lower == n);
            assert(range.higher == n);
            assert(range.alignment is range.Alignment.Normal);
            assert(range.delta == 0);
            assert(range.length == 0);
            assert(range.asrange(1).empty);
            static if(isIntegral!T) assert(range.asrange.empty);
            assert(range == range);
            assert(range >= range);
            assert(range <= range);
            assert(!(range > range));
            assert(!(range < range));
            assert(range in range);
            assert(0 !in range);
            assert(n !in range);
            assert(double.infinity !in range);
            assert(numrange(T(0), T(10)) !in range);
            assert(range in numrange(T(0), T(n)));
        }
    }
}

unittest{ /// Normal ranges
    auto range = numrange!int(0, 10);
    assert(range.low == 0);
    assert(range.high == 10);
    assert(range.lower == 0);
    assert(range.higher == 10);
    assert(range.alignment is range.Alignment.Normal);
    assert(range.delta == 10);
    assert(range.length == 10);
    assert(range.asrange.equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    assert(range.asrange(2).equals([0, 2, 4, 6, 8]));
    assert(0 in range);
    assert(5 in range);
    assert(10 !in range);
    assert(-5 !in range);
    assert(-10 !in range);
    assert(-20 !in range);
    assert(range in range);
    assert(numrange(1, 2) in range);
    assert(numrange(-1, 1) !in range);
    assert(numrange(5, 11) !in range);
    assert(numrange(20, 25) !in range);
    assert(numrange(1, 2).overlaps(range));
    assert(numrange(-1, 1).overlaps(range));
    assert(numrange(5, 11).overlaps(range));
    assert(!numrange(20, 25).overlaps(range));
}

unittest{ /// Addition and subtraction operator overloads
    auto range = numrange!int(0, 20);
    assert(range + 5 == numrange(5, 25));
    assert(range - 5 == numrange(-5, 15));
    range += 5;
    assert(range.low == 5);
    assert(range.high == 25);
    range -= 5;
    assert(range.low == 0);
    assert(range.high == 20);
}

unittest{ /// Number range sorting
    assert(issorted([
        numrange(0, 0), numrange(0, 1), numrange(1, 1),
        numrange(2, 6), numrange(2, 8), numrange(3, 3),
        numrange(5, 3), numrange(3, 7), numrange(9, 9)
    ]));
}

unittest{ /// Inverted ranges
    auto range = numrange!int(10, 5);
    assert(range.low == 10);
    assert(range.high == 5);
    assert(range.lower == 5);
    assert(range.higher == 10);
    assert(!range.empty);
    assert(range.delta == -5);
    assert(range.length == 5);
    assert(range.asrange.equals([5, 6, 7, 8, 9]));
}

unittest{ /// Number range as range bidirectionality
    auto nrange = numrange!int(0, 4);
    auto range = nrange.asrange;
    assert(!range.empty);
    assert(range.front == 0);
    assert(range.back == 3);
    assert(range.length == 4);
    assert(range.remaining == 4);
    range.popFront();
    assert(range.front == 1);
    assert(range.length == 4);
    assert(range.remaining == 3);
    range.popBack();
    assert(range.back == 2);
    assert(range.remaining == 2);
    range.popBack();
    assert(range.back == 1);
    assert(range.remaining == 1);
    range.popFront();
    assert(range.empty);
    assert(range.remaining == 0);
    mustthrow({range.front;});
    mustthrow({range.popFront();});
    mustthrow({range.back;});
    mustthrow({range.popBack();});
}

unittest{ /// Number range as range random access and slicing
    // Random access
    auto range = numrange!int(0, 8).asrange(2);
    assert(range.equals([0, 2, 4, 6]));
    assert(range[0] == 0);
    assert(range[1] == 2);
    assert(range[2] == 4);
    assert(range[$-1] == 6);
    mustthrow!IndexOutOfBoundsError({range[$];});
    // Slicing
    assert(range[0 .. 0].empty);
    assert(range[$ .. $].empty);
    assert(range[0 .. 1].equals([0]));
    assert(range[0 .. 2].equals([0, 2]));
    assert(range[0 .. 3].equals([0, 2, 4]));
    assert(range[0 .. $].equals([0, 2, 4, 6]));
    assert(range[1 .. $].equals([2, 4, 6]));
    assert(range[2 .. $].equals([4, 6]));
    assert(range[3 .. $].equals([6]));
    mustthrow!InvalidSliceBoundsError({range[0 .. $+1];});
}

unittest{ /// Number range as range saving
    auto range = numrange!int(0, 4).asrange;
    auto saved = range.save;
    range.popFront();
    assert(range.front == 1);
    assert(saved.front == 0);
}
