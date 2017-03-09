module mach.types.tuple;

private:

import mach.meta : Any, All;
import mach.types.types : Types, isTypes;
import mach.traits : AsUnaryOp, isUnaryOpPlural, AsBinaryOp, isBinaryOpPlural;
import mach.traits : canCastPlural, canHash, hash, isTemplateOf, isCallable;

/++ Docs

This module implements a tuple type which serves a fairly simple purpose of
holding any number of values of aribtrary types, but does so in such a way that
is accommodating to the language syntax.
Tuples overload various operators, can be indexed with compile-time bounds
checking, and can be passed to functions expecting as arguments the tuple's
constituent types by using `tuple.expand`.

`Tuple` is a template which can be used to acquire a struct representing a
tuple holding some given types, and `tuple` is a function which can be used
to acquire a tuple holding some given values.

+/

unittest{ /// Example
    // Reference a tuple type with `Tuple` or instantiate one with `tuple`.
    Tuple!(string, char) tup = tuple("hello", '!');
    static assert(tup.length == 2); /// Length is known at compile time.
    assert(tup[0] == "hello");
    assert(tup[1] == '!');
    // Out-of-bounds indexes produce a compile error!
    static assert(!is(typeof({tup[2];})));
}

unittest{ /// Example
    // Unary operators are simply applied to every member of the tuple.
    // They are only allowed when every member of the tuple supports the operator.
    Tuple!(int, int) itup = tuple(1, 2);
    Tuple!(float, float) ftup = cast(Tuple!(float, float)) itup;
    assert(-itup == tuple(-1, -2));
    assert(-itup == -ftup);
}

unittest{ /// Example
    // Binary operators are applied to every pair of elements in tuples.
    // They're only allowed when every pair of elements supports the operator.
    auto tup = tuple(1, 2, 3);
    assert(tup + tuple(4, 5, 6) == tuple(5, 7, 9));
    assert(tup - tuple(1, 1, 1) == tuple(0, 1, 2));
}

unittest{ /// Example
    // Tuples can be ordered if their corresponding pairs of elements can be ordered.
    // The second elements are compared only if the first are equal, the third
    // only if the second are equal, etc., in a manner similar to string sorting.
    assert(tuple(0, 1) < tuple(1, 1));
    assert(tuple(1, 1) > tuple(1, 0));
}

public:



/// Determine whether a type is a tuple.
/// To qualify as a tuple, the type must:
/// - Have a `length` known at compile time of type `size_t`.
/// - Valid `foreach(i, element; tuple)` such that `i` is known at compile time.
/// - Must support indexing i.e. `tuple[0]`.
/// - Accessing an out-of-bounds index via indexing must produce a compile error.
template isTuple(T...) if(T.length == 1){
    enum bool isTuple = is(typeof({
        enum size_t length = T[0].init.length;
        auto ex = T[0].init.expand;
        foreach(i, _; T[0].init){
            enum j = i;
            auto x = T[0].init[i];
        }
        static if(length != 0){
            auto x = T[0].init[0] == T[0].init[length - 1];
        }
        static assert(!is(typeof({
            T[0].init[length];
        })));
    }));
}



/// Build a tuple from the given values.
auto tuple(T...)(T args){
    return Tuple!T(args);
}



private template canTupleOp(alias op, L, R...){
    static if(R.length == 1){
        static if(isTuple!L && isTuple!R){
            enum bool canTupleOp = (
                isBinaryOpPlural!(op, L.Types, R[0].Types)
            );
        }else{
            enum bool canTupleOp = false;
        }
    }else{
        enum bool canTupleOp = false;
    }
}

private template canUnaryOpTuple(alias op, T){
    static if(isTuple!T){
        alias canUnaryOpTuple = isUnaryOpPlural!(op, T.T);
    }else{
        enum bool canUnaryOpTuple = false;
    }
}

private template canUnaryOpTuple(string op, T){
    alias canUnaryOpTuple = canUnaryOpTuple!(AsUnaryOp!op, T);
}

private template canBinaryOpTuple(string op, L, R...){
    alias canBinaryOpTuple = canTupleOp!(AsBinaryOp!op, L, R);
}

private template canAssignTuple(L, R...){
    alias canAssignTuple = canOpAssignTuple!(``, L, R);
}

private template canOpAssignTuple(string op, L, R...){
    alias assign = (a, b){mixin(`a ` ~ op ~ `= b;`); return 0;};
    alias canOpAssignTuple = canTupleOp!(assign, L, R);
}

private template canCastTuple(From, To){
    static if(isTuple!From && isTuple!To){
        enum bool canCastTuple = canCastPlural!(From.Types, To.Types);
    }else{
        enum bool canCastTuple = false;
    }
}



/// Encapsulate an arbitrary number of values of arbitrary types.
struct Tuple(X...){
    alias T = X;
    alias Types = .Types!X;
    
    /// The number of types represented by this struct.
    static enum length = T.length;
    /// True when the sequence of types is empty.
    static enum bool empty = T.length == 0;
    alias opDollar = length;
    
    T expand;
    
    alias expand this;
    
    static if(T.length){
        this(T values){
            this.expand = values;
        }
    }else{
        /// Silence default constructor nonsense, allow construction with
        /// an empty list of arguments.
        static typeof(this) opCall(){
            typeof(this) value; return value;
        }
    }
    
    /// Return another tuple which contains a slice of those values in this one.
    auto ref slice(size_t low, size_t high)() if(
        low >= 0 && high >= low && high <= this.length
    ){
        return tuple(this.expand[low .. high]);
    }
    
    /// Return a tuple which is a concatenation of this and some other tuples.
    auto ref concat(Args...)(auto ref Args args) if(All!(isTuple, Args)){
        static if(Args.length == 0){
            return this;
        }else static if(Args.length == 1){
            return Tuple!(T, Args[0].T)(this.expand, args[0].expand);
        }else{
            return this.concat(args[0]).concat(args[1 .. $]);
        }
    }
    
    /// Return a tuple for which each value is the result of applying a unary
    /// operator to every value of this tuple.
    auto ref opUnary(string op)() if(
        canUnaryOpTuple!(op, typeof(this))
    ){
        static if(op == `++` || op == `--`){
            foreach(i, _; T){
                mixin(op ~ `this.expand[i];`);
            }
            return this;
        }else{
            alias UnOp = AsUnaryOp!op;
            static if(T.length == 0){
                return this;
            }else static if(T.length == 1){
                return tuple(UnOp(this.expand));
            }else{
                return tuple(
                    UnOp(this.expand[0]),
                    this.slice!(1, this.length).opUnary!op().expand
                );
            }
        }
    }
    
    /// Return a tuple for which each value is the result of applying a binary
    /// operator to every pair of values between this tuple and another.
    auto ref opBinary(string op, R)(auto ref R rhs) if(
        canBinaryOpTuple!(op, typeof(this), R)
    ){
        alias BinOp = AsBinaryOp!op;
        static if(T.length == 0){
            return this;
        }else static if(T.length == 1){
            return tuple(BinOp(this.expand, rhs.expand));
        }else{
            return tuple(
                BinOp(this.expand[0], rhs.expand[0]),
                this.slice!(1, this.length).opBinary!op(
                    rhs.slice!(1, rhs.length)
                ).expand
            );
        }
    }
    
    auto ref opBinary(string op, R...)(auto ref R rhs) if(
        !canBinaryOpTuple!(op, typeof(this), R) &&
        isBinaryOpPlural!(AsBinaryOp!op, Types, .Types!R)
    ){
        return this.opBinary!op(tuple(rhs));
    }
    
    auto ref opBinaryRight(string op, L...)(auto ref L lhs) if(
        !canBinaryOpTuple!(op, L, typeof(this)) &&
        isBinaryOpPlural!(AsBinaryOp!op, .Types!L, Types)
    ){
        return tuple(lhs).opBinary!op(this);
    }
    
    void opAssign(R...)(auto ref R rhs) if(
        canAssignTuple!(typeof(this), R)
    ){
        foreach(i, _; T) this.expand[i] = rhs[0].expand[i];
    }
    
    void opAssign(R...)(auto ref R rhs) if(
        !canAssignTuple!(typeof(this), R) &&
        isBinaryOpPlural!((a, b){a = b; return 0;}, Types, .Types!R)
    ){
        foreach(i, _; T) this.expand[i] = rhs[i];
    }
    
    void opOpAssign(string op, R...)(auto ref R rhs) if(
        canOpAssignTuple!(op, typeof(this), R)
    ){
        foreach(i, _; T) mixin(`this.expand[i] ` ~ op ~ `= rhs[0].expand[i];`);
    }
    
    void opOpAssign(string op, R...)(auto ref R rhs) if(
        !canOpAssignTuple!(op, typeof(this), R) &&
        isBinaryOpPlural!((a, b){mixin(`a ` ~ op ~ `= b;`); return 0;}, Types, .Types!R)
    ){
        foreach(i, _; T) mixin(`this.expand[i] ` ~ op ~ `= rhs[i];`);
    }
    
    /// Compare equality of each pair of values with another tuple.
    auto ref opEquals(R)(auto ref R rhs) if(
        canBinaryOpTuple!(`==`, typeof(this), R)
    ){
        foreach(i, _; T){
            if(!(this.expand[i] == rhs[i])) return false;
        }
        return true;
    }
    
    /// Compare equality of each pair of values with a compatible sequence of
    /// arguments.
    auto opEquals(R...)(auto ref R rhs) if(
        !canBinaryOpTuple!(`==`, typeof(this), R) &&
        isBinaryOpPlural!(AsBinaryOp!`==`, Types, .Types!R)
    ){
        return this.opEquals(tuple(rhs));
    }
    
    /// Compares pairs of values between two tuples from front to back until
    /// one member of a pair is found to be greater than the other - in which
    /// case this method returns a positive value - or less than the other -
    /// in which case this method returns a negative value.
    /// If both tuples are empty, or if no pairs have a greater or lesser value,
    /// then this method returns zero.
    /// Think of it like ordering strings alphabetically, where each string is
    /// actually a tuple of characters.
    auto opCmp(R)(auto ref R rhs) if(
        canBinaryOpTuple!(`>`, typeof(this), R) &&
        canBinaryOpTuple!(`<`, typeof(this), R)
    ){
        static if(T.length == 0){
            return 0;
        }else{
            foreach(i, _; rhs){
                if(this.expand[i] > rhs[i]){
                    return 1;
                }else if(this.expand[i] < rhs[i]){
                    return -1;
                }else{
                    static if(T.length == 1){
                        return 0;
                    }else{
                        return this.slice!(1, this.length).opCmp(
                            rhs.slice!(1, rhs.length)
                        );
                    }
                }
            }
            return true;
        }
    }
    
    auto opCmp(R...)(auto ref R rhs) if(
        !(
            canBinaryOpTuple!(`>`, typeof(this), R) &&
            canBinaryOpTuple!(`<`, typeof(this), R)
        ) && (
            isBinaryOpPlural!(AsBinaryOp!`>`, Types, .Types!R) &&
            isBinaryOpPlural!(AsBinaryOp!`<`, Types, .Types!R)
        )
    ){
        return this.opCmp(tuple(rhs));
    }
    
    /// Cast this tuple to another type of tuple.
    auto opCast(To)() if(canCastTuple!(typeof(this), To)){
        static if(To.length == 0){
            return this;
        }else static if(To.length == 1){
            return tuple(cast(To.T[0]) this.expand[0]);
        }else{
            return tuple(
                cast(To.T[0]) this.expand[0],
                this.slice!(1, this.length).opCast!(
                    typeof(To.init.slice!(1, To.length)())
                ).expand
            );
        }
    }
    
    /// When there is only a single element in the tuple, allow it to
    /// be cast to any type that the single element can be cast to.
    auto opCast(To)() if(
        T.length == 1 && !canCastTuple!(typeof(this), To) && is(typeof({
            auto x = cast(To) this.expand[0];
        }))
    ){
        return cast(To) this.expand[0];
    }
    
    /// Get a hash which is a function of the hashes of each item in the
    /// tuple.
    size_t toHash()() if(All!(canHash, T)){
        static if(T.length == 0){
            return 0;
        }else static if(T.length == 1){
            return this.expand[0].hash;
        }else{
            size_t h = T.length;
            foreach(i, _; T){
                h ^= this.expand[0].hash;
            }
            return h;
        }
    }
}



version(unittest){
    private:
    struct TupRange(T...){
        Tuple!T t;
        bool empty = false;
        @property auto front(){return t;}
        void popFront(){this.empty = true;}
    }
}

unittest{ /// isTuple template
    static assert(isTuple!(Tuple!()));
    static assert(isTuple!(Tuple!(int)));
    static assert(isTuple!(Tuple!(int, int)));
    static assert(!isTuple!(int));
    static assert(!isTuple!(int[]));
    static assert(!isTuple!(int[4]));
    static assert(!isTuple!(string));
    static assert(!isTuple!(void));
}

unittest{ /// Empty tuple
    {
        auto t = tuple();
        static assert(t.length == 0);
        static assert(t.empty);
        static assert(!is(typeof({t[0];})));
        assert(t == t);
        assert(t + t == t);
        assert(!(t < t));
        assert(t <= t);
        assert(t.slice!(0, 0) is t);
        assert(t.concat(t) == t);
        assert(t.hash == tuple().hash);
        t = t;
        t += t;
        t = cast(Tuple!()) t;
    }
    {
        foreach(value; tuple()){
            assert(false);
        }
    }
    {
        TupRange!() range;
        foreach(value; range){
            static assert(is(typeof(value) == Tuple!()));
        }
    }
}

unittest{ /// Single-element tuple
    {
        auto t = tuple(0);
        static assert(t.length == 1);
        static assert(!t.empty);
        assert(t.expand[0] == 0);
        assert(t[0] == 0);
        assert(t == t);
        assert(t >= t);
        assert(!(t > t));
        assert(t + 1 == 1);
        assert(t - 1 == -1);
        assert(t.slice!(0, 1) is t);
        assert(t.slice!(0, 0) == tuple());
        assert(t.slice!(1, 1) == tuple());
        assert(t.hash == tuple(0).hash);
    }
    {
        TupRange!int range;
        foreach(value; range){
            static assert(is(typeof(value) == Tuple!int));
        }
    }
    {
        auto t = tuple(0);
        t += 1;
        assert(t == 1);
        auto sum = t + t;
        static assert(is(typeof(t) == typeof(sum)));
        assert(sum == 2);
        assert(sum > t);
        assert(t <= sum);
        t = sum;
        assert(t == sum);
        t += sum;
        assert(t == sum * 2);
        assert(t == 4);
        t++;
        assert(t == 5);
    }
    {
        auto i = tuple!int(0);
        auto f = cast(float) i;
        static assert(is(typeof(f) == float));
        assert(f == 0);
    }
    {
        auto i = tuple!int(0);
        auto f = cast(Tuple!float) i;
        static assert(is(typeof(f) == Tuple!float));
        assert(f == 0);
    }
}

unittest{ /// Multiple-element tuple
    {
        auto t = tuple(0, 1);
        static assert(t.length == 2);
        static assert(!t.empty);
        assert(t[0] == 0);
        assert(t[1] == 1);
        assert(t == t);
        assert(t >= t);
        assert(!(t > t));
        assert(t + tuple(1, 2) == tuple(1, 3));
        assert(-t == tuple(0, -1));
        assert(t.slice!(0, 2) is t);
        assert(t.slice!(0, 1) == tuple(t[0]));
        assert(t.slice!(0, 0) == tuple());
        assert(t.slice!(2, 2) == tuple());
        assert(t.concat(t) == tuple(0, 1, 0, 1));
        assert(t.hash == tuple(0, 1).hash);
    }
    {
        TupRange!(int, int) range;
        foreach(value; range){
            static assert(is(typeof(value) == Tuple!(int, int)));
        }
        foreach(x, y; range){
            static assert(is(typeof(x) == int));
            static assert(is(typeof(y) == int));
        }
    }
    {
        TupRange!(string, string, int, int) range;
        foreach(value; range){
            static assert(is(typeof(value) == Tuple!(string, string, int, int)));
        }
        foreach(x, y, z, w; range){
            static assert(is(typeof(x) == string));
            static assert(is(typeof(y) == string));
            static assert(is(typeof(z) == int));
            static assert(is(typeof(w) == int));
        }
    }
    {
        auto t = tuple(0, 1);
        t++;
        assert(t[0] == 1);
        assert(t[1] == 2);
        t *= tuple(2, 2);
        assert(t[0] == 2);
        assert(t[1] == 4);
        t = t - tuple(1, 1);
        assert(t[0] == 1);
        assert(t[1] == 3);
    }
    {
        auto i = tuple!(int, int)(0, 1);
        auto f = cast(Tuple!(float, float)) i;
        static assert(is(typeof(f) == Tuple!(float, float)));
        assert(f == i);
    }
}

unittest{ /// Concatenation
    assert(tuple().concat() is tuple());
    assert(tuple().concat(tuple()) is tuple());
    assert(tuple().concat(tuple(), tuple()) is tuple());
    assert(tuple().concat(tuple(1)) is tuple(1));
    assert(tuple(1).concat(tuple()) is tuple(1));
    assert(tuple().concat(tuple(1, 2)) is tuple(1, 2));
    assert(tuple(0).concat(tuple(1, 2)) is tuple(0, 1, 2));
    assert(tuple().concat(tuple(1), tuple(2, 3), tuple(4)) is tuple(1, 2, 3, 4));
    assert(tuple(0, 0).concat(tuple(1), tuple(2, 3), tuple(4)) is tuple(0, 0, 1, 2, 3, 4));
}
