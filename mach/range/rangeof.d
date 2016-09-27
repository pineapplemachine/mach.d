module mach.range.rangeof;

private:

import mach.traits : CommonType, hasCommonType;
import mach.range.asrange : asarrayrange;
import mach.error : enforcebounds;

public:



/// Get whether calling rangeof with an implicit element type is valid for
/// arguments of the given types.
template canMakeImplicitRangeOf(V...){
    enum bool canMakeImplicitRangeOf = hasCommonType!V;
}

/// Get whether calling rangeof with an explicit element type is valid for
/// arguments of the given types.
template canMakeExplicitRangeOf(T, V...){
    static if(V.length == 0){
        enum bool canMakeExplicitRangeOf = true;
    }else{
        enum bool canMakeExplicitRangeOf = (
            is(typeof({T x = V[$-1].init;})) &&
            canMakeExplicitRangeOf!(T, V[0 .. $-1])
        );
    }
}



/// Get a range for iterating over some set of values passed as variadic args.
auto rangeof(T, Values...)(Values values) if(canMakeExplicitRangeOf!(T, Values)){
    static if(Values.length == 0){
        EmptyRangeOf!T range; return range;
    }else static if(Values.length == 1){
        return SingularRangeOf!T(values[0]);
    }else{
        T[values.length] array = [values];
        return array.asarrayrange;
    }
}

/// ditto
auto rangeof(Values...)(Values values) if(canMakeImplicitRangeOf!Values){
    static if(Values.length == 0){
        EmptyRangeOf!() range; return range;
    }else static if(Values.length == 1){
        return SingularRangeOf!(Values[0])(values[0]);
    }else{
        CommonType!Values[values.length] array = [values];
        return array.asarrayrange;
    }
}

/// Get an infinite range where every element is the given value.
auto infrangeof(T)(T value){
    return InfSingularRangeOf!T(value);
}

/// Get a finite range of a given length where every element is the given value.
auto finiterangeof(T)(size_t length, T value){
    return FiniteSingularRangeOf!T(length, value);
}



/// Element used by EmptyRangeOf type if no other type is provided.
struct DefaultEmptyRangeOfElement{}

/// Represents an empty range of a given element type.
struct EmptyRangeOf(T = DefaultEmptyRangeOfElement){
    static enum bool empty = true;
    static enum size_t length = 0;
    static enum size_t remaining = 0;
    alias opDollar = length;
    @property T front(){assert(false, "Empty range has no front.");}
    @property T back(){assert(false, "Empty range has no back.");}
    void popFront(){assert(false, "Range is already empty.");}
    void popBack(){assert(false, "Range is already empty.");}
    @property typeof(this) save(){return this;}
    T opIndex(in size_t index){assert(false, "Empty range has no elements.");}
    typeof(this) opSlice(in size_t low, in size_t high){
        assert(low == 0 && high == 0, "Slice indexes out of bounds.");
        return this;
    }
}

/// Represents a range containing a single element.
struct SingularRangeOf(T){
    T value;
    bool isempty = false;
    static enum size_t length = 1;
    alias opDollar = length;
    @property bool empty() const{return this.isempty;}
    @property size_t remaining() const{return this.isempty ? 0 : 1;}
    @property auto front() in{assert(!this.empty);} body{return this.value;}
    @property auto back() in{assert(!this.empty);} body{return this.value;}
    void popFront() in{assert(!this.empty);} body{this.isempty = true;}
    void popBack() in{assert(!this.empty);} body{this.isempty = true;}
    @property typeof(this) save(){return this;}
    auto opIndex(in size_t index) in{assert(index == 0);} body{return this.value;}
    typeof(this) opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high <= 1);
    }body{
        return typeof(this)(this.value, low == high);
    }
}

/// Represents a finite range where every item is a single element.
struct FiniteSingularRangeOf(T){
    T value;
    size_t values;
    size_t index = 0;
    this(size_t length){
        this(length, T.init, 0);
    }
    this(size_t length, T value, size_t index = 0){
        this.value = value;
        this.values = length;
        this.index = index;
    }
    @property bool empty() const{return this.index >= this.values;}
    @property auto length() const{return this.values;}
    @property auto remaining() const{return this.values - this.index;}
    alias opDollar = length;
    @property auto front() in{assert(!this.empty);} body{return this.value;}
    @property auto back() in{assert(!this.empty);} body{return this.value;}
    void popFront() in{assert(!this.empty);} body{this.index++;}
    void popBack() in{assert(!this.empty);} body{this.index++;}
    @property typeof(this) save(){return this;}
    auto opIndex(in size_t index) in{enforcebounds(index, this);} body{
        return this.value;
    }
    auto opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
        return typeof(this)(high - low, this.value, 0);
    }
}

/// Represents an infinite range where every item is a single element.
struct InfSingularRangeOf(T){
    static enum bool empty = false;
    T value;
    @property auto front(){return this.value;}
    @property auto back(){return this.value;}
    void popFront() const{}
    void popBack() const{}
    @property typeof(this) save(){return this;}
    auto opIndex(in size_t index){return this.value;}
    // TODO: opSlice should really be meaningful for this range but that will
    // be tricky to get right.
}



version(unittest){
    private:
    import mach.test;
    import mach.traits : isInfiniteIterable;
    import mach.range.compare : equals;
}
unittest{
    tests("Range of", {
        tests("Empty", {
            void testcommon(T)(T range){
                test(range.empty);
                testeq(range.length, 0);
                testeq(range.remaining, 0);
                testeq(range[0 .. 0], range);
                testeq(range[0 .. $], range);
                testfail({range.front;});
                testfail({range.back;});
                testfail({range.popFront;});
                testfail({range.popBack;});
                testfail({range[0];});
                testfail({range[0 .. 1];});
            }
            tests("Implicit element type", {
                auto range = rangeof();
                testcommon(range);
            });
            tests("Explicit element type", {
                auto range = rangeof!int();
                static assert(is(typeof(range.front) == int));
                testcommon(range);
            });
        });
        tests("Singular", {
            void testcommon(T, V)(T range, V value){
                testf(range.empty);
                testeq(range.length, 1);
                testeq(range.remaining, 1);
                testeq(range.front, value);
                testeq(range.back, value);
                testeq(range[0], value);
                testeq(range[0 .. 1][0], value);
                test(range[0 .. 0].empty);
                test(range[1 .. 1].empty);
                test(range[0 .. 1].equals([value]));
                test(range[0 .. $].equals([value]));
                testfail({range[2];});
                testfail({range[0 .. 2];});
                range.popFront();
                test(range.empty);
                testeq(range.length, 1);
                testeq(range.remaining, 0);
                testfail({range.front;});
                testfail({range.back;});
                testfail({range.popFront;});
                testfail({range.popBack;});
            }
            tests("Implicit element type", {
                testcommon(rangeof(0), 0);
                testcommon(rangeof(4), 4);
                testcommon(rangeof("hi"), "hi");
            });
            tests("Explicit element type", {
                testcommon(rangeof!int(0), 0);
                testcommon(rangeof!uint(4), 4);
                testcommon(rangeof!string("hi"), "hi");
                auto range = rangeof!double(0);
                static assert(is(typeof(range.front) == double));
            });
        });
        tests("Infinite singular", {
            auto range = infrangeof!int(0);
            static assert(isInfiniteIterable!range);
            testf(range.empty);
            testeq(range[0], 0);
            testeq(range[size_t.max], 0);
            testeq(range.front, 0);
            testeq(range.back, 0);
            range.popFront();
            range.popBack();
            testeq(range.front, 0);
            testeq(range.back, 0);
        });
        tests("Finite singular", {
            auto range = finiterangeof!int(4, 0);
            testf(range.empty);
            testeq(range.length, 4);
            testeq(range.remaining, 4);
            tests("Random access", {
                testeq(range[0], 0);
                testeq(range[1], 0);
                testeq(range[$-1], 0);
                testfail({range[$];});
            });
            tests("Slicing", {
                test!equals(range[0 .. 0], new int[0]);
                test!equals(range[0 .. 1], [0]);
                test!equals(range[0 .. $], range);
                testfail({range[0 .. 5];});
            });
            testeq(range.front, 0);
            testeq(range.back, 0);
            range.popFront();
            range.popBack();
            testeq(range.front, 0);
            testeq(range.back, 0);
            range.popFront();
            range.popFront();
            test(range.empty);
            testeq(range.remaining, 0);
            testfail({range.front;});
            testfail({range.popFront;});
            testfail({range.back;});
            testfail({range.popBack;});
        });
        tests("Plural", {
            void testcommon(T, V)(T range, V values){
                testf(range.empty);
                testeq(range.length, values.length);
                testeq(range.remaining, values.length);
                testeq(range.front, values[0]);
                testeq(range.back, values[$-1]);
                testeq(range[0], values[0]);
                testeq(range[0 .. 1][0], values[0]);
                test(range[0 .. 0].empty);
                test(range[1 .. 1].empty);
                test!equals(range[0 .. 1], values[0 .. 1]);
                test!equals(range[0 .. $], values);
                testfail({range[values.length + 1];});
                testfail({range[0 .. values.length + 1];});
                foreach(i; values) range.popFront();
                test(range.empty);
                testeq(range.remaining, 0);
                testfail({range.front;});
                testfail({range.back;});
                testfail({range.popFront;});
                testfail({range.popBack;});
            }
            tests("Implicit element type", {
                testcommon(rangeof(0, 1), [0, 1]);
                testcommon(rangeof(1, 2, 3, 4), [1, 2, 3, 4]);
                testcommon(rangeof("hi", "yo", "sup"), ["hi", "yo", "sup"]);
            });
            tests("Explicit element type", {
                testcommon(rangeof!int(0, 1), [0, 1]);
                testcommon(rangeof!uint(1, 2, 3, 4), [1, 2, 3, 4]);
                testcommon(rangeof!string("hi", "yo", "sup"), ["hi", "yo", "sup"]);
                auto range = rangeof!double(0, 1);
                static assert(is(typeof(range.front) == double));
            });
        });
    });
}
