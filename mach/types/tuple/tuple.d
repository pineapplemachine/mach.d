module mach.types.tuple.tuple;

private:

import mach.meta : Any, All, Contains, IndexOf;
import mach.types.types : Types, isTypes;
import mach.traits : AsUnaryOp, isUnaryOpPlural, AsBinaryOp, isBinaryOpPlural;
import mach.traits : isTemplateOf, isCallable;

public:



template isBaseTuple(T...) if(T.length == 1){
    enum bool isBaseTuple = isTemplateOf!(T, Tuple);
}



auto tuple(T...)(T args){
    return Tuple!T(args);
}



template canTupleOp(alias op, L, R...){
    static if(R.length == 1){
        static if(isBaseTuple!L && isBaseTuple!R){
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

template canUnaryOpTuple(alias op, T){
    static if(isBaseTuple!T){
        alias canUnaryOpTuple = isUnaryOpPlural!(op, T.T);
    }else{
        enum bool canUnaryOpTuple = false;
    }
}

template canUnaryOpTuple(string op, T){
    alias canUnaryOpTuple = canUnaryOpTuple!(AsUnaryOp!op, T);
}

template canBinaryOpTuple(string op, L, R...){
    alias canBinaryOpTuple = canTupleOp!(AsBinaryOp!op, L, R);
}

template canAssignTuple(L, R...){
    alias canAssignTuple = canOpAssignTuple!(``, L, R);
}

template canOpAssignTuple(string op, L, R...){
    alias assign = (a, b){mixin(`a ` ~ op ~ `= b;`); return 0;};
    alias canAssignTuple = canTupleOp!(assign, L, R);
}



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
        // Silence default constructor nonsense
        static typeof(this) opCall(){
            typeof(this) value; return value;
        }
    }
    
    auto ref slice(size_t low, size_t high)() if(
        low >= 0 && high >= low && high <= this.length
    ){
        return tuple(this.expand[low .. high]);
    }
    
    auto ref concat(Args...)(auto ref Args args) if(All!(isBaseTuple!Args)){
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
        foreach(i, _; T) this.expand[i] = rhs[i];
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
        foreach(i, _; T) mixin(`this.expand[i] ` ~ op ~ `= rhs[i];`);
    }
    
    void opOpAssign(string op, R...)(auto ref R rhs) if(
        !canOpAssignTuple!(op, typeof(this), R) &&
        isBinaryOpPlural!((a, b){mixin(`a ` ~ op ~ `= b;`); return 0;}, Types, .Types!R)
    ){
        foreach(i, _; T) mixin(`this.expand[i] ` ~ op ~ `= rhs[i];`);
    }
    
    auto ref opEquals(R)(auto ref R rhs) if(
        canBinaryOpTuple!(`==`, typeof(this), R)
    ){
        foreach(i, _; T){
            if(!(this.expand[i] == rhs[i])) return false;
        }
        return true;
    }
    
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
    
    static if(T.length == 1){
        auto opCast(T)() if(is(typeof({
            auto x = cast(T) this.expand[0];
        }))){
            return cast(T) this.expand[0];
        }
    }
}



//import mach.io.log;

// TODO
unittest{
    //auto t = tuple(1, 2);
    //log(t);
    //log(t[0]);
    //log(t + tuple(0.0, 2.0));
    //log(-t);
    //log(t + t.expand);
    //log(t == t);
    //log(t == t.expand);
    //log(t >= t);
    //log(t >= t.expand);
    //static assert(isTemplateOf!(typeof(t), Tuple));
}
unittest{
    //auto t = tuple(0);
    //log(t + 1);
    //log(1 + t);
}
unittest{
    //Tuple!() t;
    //auto t2 = Tuple!()(t.expand);
}
