module mach.range.rangeof;

private:

import mach.traits : CommonType, hasCommonType;
import mach.range.asrange : asarrayrange;

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



/// Element used by EmptyRangeOf type if no other type is provided.
struct DefaultEmptyRangeOfElement{}

/// Represents an empty range of a given element type.
struct EmptyRangeOf(T = DefaultEmptyRangeOfElement){
    static enum bool empty = true;
    static enum size_t length = 0;
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
    
    @property bool empty(){return this.isempty;}
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



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Range of", {
        tests("Empty", {
            void testcommon(T)(T range){
                test(range.empty);
                testeq(range.length, 0);
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
        tests("Plural", {
            void testcommon(T, V)(T range, V values){
                testf(range.empty);
                testeq(range.length, values.length);
                testeq(range.front, values[0]);
                testeq(range.back, values[$-1]);
                testeq(range[0], values[0]);
                testeq(range[0 .. 1][0], values[0]);
                test(range[0 .. 0].empty);
                test(range[1 .. 1].empty);
                test(range[0 .. 1].equals(values[0 .. 1]));
                test(range[0 .. $].equals(values));
                testfail({range[values.length + 1];});
                testfail({range[0 .. values.length + 1];});
                foreach(i; values) range.popFront();
                test(range.empty);
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
