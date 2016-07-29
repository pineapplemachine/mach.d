module mach.traits.op;

private:

import std.meta : staticIndexOf;
import std.traits : isImplicitlyConvertible, Unqual;

public:



template hasBinaryOp(Lhs, string op){
    alias hasBinaryOp = hasBinaryOp!(Lhs, Lhs, op);
}

template hasBinaryOp(Lhs, Rhs, string op){
    enum bool hasBinaryOp = is(typeof((inout int = 0){
        mixin(`auto result = Lhs.init ` ~ op ~ ` Rhs.init;`);        
    }));
}

template opBinaryResult(Lhs, Rhs, string op) if(hasBinaryOp!(Lhs, Rhs, op)){
    mixin(`alias opBinaryResult = typeof(Lhs.init ` ~ op ~ ` Rhs.init);`);
}



enum canCompare(Lhs, string op) = canCompare!(Lhs, Lhs, op);
enum canCompare(Lhs, Rhs, string op) = hasBinaryOp!(Lhs, Rhs, op) && isImplicitlyConvertible!(opBinaryResult!(Lhs, Rhs, op), bool);

enum canCompare(Lhs) = canCompare!(Lhs, Lhs);

enum canCompare(Lhs, Rhs) = (
    canCompare!(Lhs, Rhs, ">") &&
    canCompare!(Lhs, Rhs, "<") &&
    canCompare!(Lhs, Rhs, ">=") &&
    canCompare!(Lhs, Rhs, ">=") &&
    canCompare!(Lhs, Rhs, "==")
);



template hasUnaryOp(T, string op){
    enum bool hasUnaryOp = is(typeof((inout int = 0){
        mixin(`T value = T.init; value++;`);
    }));
}

enum canIncrement(T) = hasUnaryOp!(T, "++");
enum canDecrement(T) = hasUnaryOp!(T, "--");



template hasOpApply(Tx...) if(Tx.length == 1){
    enum bool hasOpApply = is(typeof(Tx[0].opApply));
}
template hasOpApplyReverse(Tx...) if(Tx.length == 1){
    enum bool hasOpApplyReverse = is(typeof(Tx[0].opApplyReverse));
}



/// True when From can be explicitly casted to To.
template canCast(From, To){
    enum bool canCast = is(From == To) || is(typeof((inout int = 0){
        From from = From.init;
        To to = cast(To) from;
    }));
}



unittest{
    // TODO: more tests
    
    static assert(hasBinaryOp!(int, "+"));
    static assert(hasBinaryOp!(int, long, "+"));
    
    static assert(canCompare!(int));
    static assert(canCompare!(int, long));
}
