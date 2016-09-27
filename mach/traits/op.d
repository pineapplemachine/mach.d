module mach.traits.op;

private:

import mach.types.types : isTypes;

public:



alias isBinaryOp = isBinaryOpSingular;

/// Given an operator, return a function which takes two arguments and
/// returns the application of that operator upon them.
template AsBinaryOp(string op){
    mixin(`alias AsBinaryOp = (a, b) => (a ` ~ op ~ ` b);`);
}

/// Determine whether the given function is valid as a unary operation
/// upon the given pair of types.
template isBinaryOpSingular(alias op, lhs, rhs){
    enum bool isBinaryOpSingular = is(typeof({
        auto x = op(lhs.init, rhs.init);
    }));
}

/// Determine whether the given function is valid as a unary operation
/// upon all the given pairs of types, where each item in the first list
/// of types is checked for compatibility with the corresponding item
/// in the second list.
template isBinaryOpPlural(alias op, ltypes, rtypes) if(
    isTypes!ltypes && isTypes!rtypes
){
    static if(ltypes.length == rtypes.length){
        static if(ltypes.length == 0){
            enum bool isBinaryOpPlural = true;
        }else static if(ltypes.length == 1){
            enum bool isBinaryOpPlural = isBinaryOpSingular!(
                op, ltypes.index!0, rtypes.index!0
            );
        }else{
            enum bool isBinaryOpPlural = (
                isBinaryOpSingular!(op, ltypes.index!0, rtypes.index!0) &&
                isBinaryOpPlural!(op, ltypes.slice!(1, ltypes.length), rtypes.slice!(1, rtypes.length))
            );
        }
    }else{
        enum bool isBinaryOpPlural = false;
    }
}



alias isUnaryOp = isUnaryOpPlural;

/// Given an operator, return a function which takes one argument and
/// returns the application of that operator upon it.
template AsUnaryOp(string op){
    mixin(`alias AsUnaryOp = (a) => (` ~ op ~ `a);`);
}

/// Determine whether the given function is valid as a unary operation
/// upon the given type.
template isUnaryOpSingular(alias op, T){
    enum bool isUnaryOpSingular = is(typeof({
        auto x = op(T.init);
    }));
}

/// Determine whether the given function is valid as a unary operation
/// upon all the given types.
template isUnaryOpPlural(alias op, T...){
    static if(T.length == 0){
        enum bool isUnaryOpPlural = true;
    }else static if(T.length == 1){
        enum bool isUnaryOpPlural = isUnaryOpSingular!(op, T[0]);
    }else{
        enum bool isUnaryOpPlural = (
            isUnaryOpSingular!(op, T[0]) &&
            isUnaryOpPlural!(op, T[1 .. $])
        );
    }
}



/// Determine whether some type has an opApply method.
/// Notably distinct from the isIterable template,
/// and will produce different results.
template hasOpApply(T...) if(T.length == 1){
    enum bool hasOpApply = is(typeof(T[0].opApply));
}

/// Determine whether some type has an opApplyReverse method.
/// Notably distinct from the isIterableReverse template,
/// and will produce different results.
template hasOpApplyReverse(T...) if(T.length == 1){
    enum bool hasOpApplyReverse = is(typeof(T[0].opApplyReverse));
}



/// True when From can be explicitly casted to To.
template canCast(From, To){
    enum bool canCast = is(typeof({
        To x = cast(To) From.init;
    }));
}



version(unittest){
    private:
    import mach.types.types : Types;
}

unittest{
    alias neg = (a) => (-a);
    alias len = (a) => (a.length);
    alias invalid = (a, b) => (a);
    static assert(isUnaryOp!(neg, int));
    static assert(isUnaryOp!(neg, double));
    static assert(isUnaryOp!(len, string));
    static assert(isUnaryOp!(len, int[]));
    static assert(!isUnaryOp!(neg, void));
    static assert(!isUnaryOp!(neg, string));
    static assert(!isUnaryOp!(len, int));
    static assert(!isUnaryOp!(invalid, int));
}
unittest{
    alias neg = (a) => (-a);
    static assert(isUnaryOpPlural!(neg));
    static assert(isUnaryOpPlural!(neg, int));
    static assert(isUnaryOpPlural!(neg, int, int, double));
    static assert(!isUnaryOpPlural!(neg, void));
    static assert(!isUnaryOpPlural!(neg, string));
    static assert(!isUnaryOpPlural!(neg, int, int, string));
}
unittest{
    assert(AsUnaryOp!`-`(1) == -1);
    assert(AsUnaryOp!`++`(1) == 2);
}

unittest{
    alias sum = (a, b) => (a + b);
    alias concat = (a, b) => (a ~ b);
    alias invalid = (a) => (a);
    static assert(isBinaryOp!(sum, int, int));
    static assert(isBinaryOp!(sum, int, double));
    static assert(isBinaryOp!(concat, string, string));
    static assert(!isBinaryOp!(sum, void, void));
    static assert(!isBinaryOp!(sum, int, string));
    static assert(!isBinaryOp!(sum, string, string));
    static assert(!isBinaryOp!(concat, int, string));
    static assert(!isBinaryOp!(concat, int, int));
    static assert(!isBinaryOp!(invalid, int, int));
}
unittest{
    alias sum = (a, b) => (a + b);
    static assert(isBinaryOpPlural!(sum, Types!(), Types!()));
    static assert(isBinaryOpPlural!(sum, Types!(int), Types!(int)));
    static assert(isBinaryOpPlural!(sum, Types!(int), Types!(double)));
    static assert(isBinaryOpPlural!(sum, Types!(int, int), Types!(int, int)));
    static assert(isBinaryOpPlural!(sum, Types!(int, int), Types!(double, double)));
    static assert(!isBinaryOpPlural!(sum, Types!(void), Types!(void)));
    static assert(!isBinaryOpPlural!(sum, Types!(), Types!(void)));
    static assert(!isBinaryOpPlural!(sum, Types!(int), Types!()));
    static assert(!isBinaryOpPlural!(sum, Types!(int), Types!(void)));
    static assert(!isBinaryOpPlural!(sum, Types!(int), Types!(int, int)));
}
unittest{
    assert(AsBinaryOp!`-`(1, 2) == -1);
    assert(AsBinaryOp!`+`(1, 2) == 3);
    assert(AsBinaryOp!`*`(1, 2) == 2);
}

unittest{
    struct None{}
    struct Fwd{int opApply(in int delegate(int)){return 0;}}
    struct FwdStatic{static int opApply(in int delegate(int)){return 0;}}
    struct Rev{int opApplyReverse(in int delegate(int)){return 0;}}
    struct RevStatic{static int opApplyReverse(in int delegate(int)){return 0;}}
    struct Both{
        int opApply(in int delegate(int)){return 0;}
        int opApplyReverse(in int delegate(int)){return 0;}
    }
    struct BothStatic{
        static int opApply(in int delegate(int)){return 0;}
        static int opApplyReverse(in int delegate(int)){return 0;}
    }
    static assert(hasOpApply!(Fwd()));
    static assert(hasOpApply!Fwd);
    static assert(hasOpApply!FwdStatic);
    static assert(hasOpApply!Both);
    static assert(hasOpApply!BothStatic);
    static assert(!hasOpApply!void);
    static assert(!hasOpApply!int);
    static assert(!hasOpApply!None);
    static assert(!hasOpApply!Rev);
    static assert(!hasOpApply!RevStatic);
    static assert(hasOpApplyReverse!(Rev()));
    static assert(hasOpApplyReverse!Rev);
    static assert(hasOpApplyReverse!RevStatic);
    static assert(hasOpApplyReverse!Both);
    static assert(hasOpApplyReverse!BothStatic);
    static assert(!hasOpApplyReverse!void);
    static assert(!hasOpApplyReverse!int);
    static assert(!hasOpApplyReverse!None);
    static assert(!hasOpApplyReverse!Fwd);
    static assert(!hasOpApplyReverse!FwdStatic);
}

unittest{
    static assert(canCast!(int, int));
    static assert(canCast!(int, const(int)));
    static assert(canCast!(const(int), int));
    static assert(canCast!(int, double));
    static assert(canCast!(double, int));
    static assert(canCast!(int, ulong));
    static assert(canCast!(ulong, int));
    static assert(canCast!(char[], string));
    static assert(!canCast!(void, void));
    static assert(!canCast!(int, void));
    static assert(!canCast!(void, int));
    static assert(!canCast!(string, int));
    static assert(!canCast!(string, float));
}
