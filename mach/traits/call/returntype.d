module mach.traits.call.returntype;

private:

import mach.traits.call.callable;

public:



/// Get the return type of some callable type.
template ReturnType(T...) if(T.length == 1 && isCallable!T){
    static if(is(CallableType!T R == return)){
        alias ReturnType = R;
    }else{
        static assert(false, "Unable to get return type.");
    }
}



/// Determine whether some callable returns a value implicitly convertible
/// to the given type.
/// Except for `void`, where the template evaluates to true only if the function
/// has no return value.
template Returns(R, T...){
    enum bool Returns = is(ReturnType!T == R) || is(typeof({
        ReturnType!T x; R y = x;
    }));
}



/// Determine whether some callable returns a value of the given type.
template ReturnsExactly(R, T...){
    enum bool ReturnsExactly = is(ReturnType!T == R);
}



/// Get the return type of a callable when invoked with the given argument types.
/// The final argument is the callable, and all previous arguments are the
/// types to try calling the callable with.
template ReturnTypeWith(T...) if(T.length && isCallableWith!T){
    alias func = T[$-1];
    alias Args = T[0 .. $-1];
    alias ReturnTypeWith = typeof({Args args = Args.init; return func(args);}());
}



/// Get whether a callable returns something implicitly convertible to the
/// given type.
/// Except for `void`, where the template evaluates to true only if the function
/// has no return value.
/// The final argument is the callable, the first argument is the return
/// type to be compared, and all other arguments are the types to try calling
/// the callable with.
template ReturnsWith(T...) if(T.length >= 2){
    alias R = T[0];
    alias W = T[1 .. $];
    enum bool ReturnsWith = is(ReturnTypeWith!W == R) || is(typeof({
        ReturnTypeWith!W x; R y = x;
    }));
}



/// Get whether a callable returns exactly the given type when called with the
/// given arguments.
/// The final argument is the callable, the first argument is the return
/// type to be compared, and all other arguments are the types to try calling
/// the callable with.
template ReturnsExactlyWith(T...) if(T.length >= 2){
    static if(isCallableWith!(T[1 .. $])){
        alias R = T[0];
        alias func = T[$-1];
        alias Args = T[1 .. $-1];
        enum bool ReturnsExactlyWith = is(ReturnTypeWith!(Args, func) == R);
    }else{
        enum bool ReturnsExactlyWith = false;
    }
}



unittest{
    void fn1(){}
    int fn2(){return 0;}
    static assert(is(ReturnType!(int function()) == int));
    static assert(is(ReturnType!(string function()) == string));
    static assert(is(ReturnType!(void function()) == void));
    static assert(is(ReturnType!(int function(int)) == int));
    static assert(is(ReturnType!(void delegate()) == void));
    static assert(is(ReturnType!(int delegate(int)) == int));
    static assert(is(ReturnType!fn1 == void));
    static assert(is(ReturnType!fn2 == int));
}
unittest{
    struct StaticCall{static int opCall(int){return 0;}}
    struct InstanceCall{int opCall(int){return 0;}}
    static assert(is(ReturnType!StaticCall == int));
    static assert(is(ReturnType!InstanceCall == int));
}

unittest{
    void fn1(){}
    int fn2(){return 0;}
    {
        static assert(ReturnsExactly!(void, fn1));
        static assert(ReturnsExactly!(void, typeof(fn1)));
        static assert(ReturnsExactly!(int, fn2));
        static assert(ReturnsExactly!(string, {return "";}));
        static assert(!ReturnsExactly!(int, fn1));
        static assert(!ReturnsExactly!(string, fn2));
        static assert(!ReturnsExactly!(int, int));
    }{
        static assert(Returns!(void, fn1));
        static assert(Returns!(void, typeof(fn1)));
        static assert(Returns!(int, fn2));
        static assert(Returns!(string, {return "";}));
        static assert(!Returns!(int, fn1));
        static assert(!Returns!(string, fn2));
        static assert(!Returns!(int, int));
    }{
        static assert(!ReturnsExactly!(long, fn2));
        static assert(!ReturnsExactly!(const int, fn2));
        static assert(Returns!(long, fn2));
        static assert(Returns!(const int, fn2));
    }
}

unittest{
    static void sfunc(){}
    void fn1(){}
    int fn2(){return 1;}
    int function(int x) fptr;
    int delegate(int x) del;
    auto fn1ptr = &fn1;
    struct OpCall{static void opCall(int x){} static int opCall(string x){return 0;}}
    {
        static assert(is(ReturnTypeWith!(fn1) == void));
        static assert(is(ReturnTypeWith!(fn2) == int));
        static assert(is(ReturnTypeWith!(int, fptr) == int));
        static assert(is(ReturnTypeWith!(int, OpCall) == void));
        static assert(is(ReturnTypeWith!(string, OpCall) == int));
    }{
        static assert(ReturnsExactlyWith!(void, fn1));
        static assert(ReturnsExactlyWith!(int, int, fptr));
        static assert(!ReturnsExactlyWith!(int, fn1));
        static assert(!ReturnsExactlyWith!(int, int, int, fptr));
    }{
        static assert(ReturnsWith!(void, fn1));
        static assert(ReturnsWith!(int, int, fptr));
        static assert(!ReturnsWith!(int, fn1));
        static assert(!ReturnsWith!(int, int, int, fptr));
    }{
        static assert(!ReturnsExactlyWith!(long, int, fptr));
        static assert(!ReturnsExactlyWith!(const int, int, fptr));
        static assert(ReturnsWith!(long, int, fptr));
        static assert(ReturnsWith!(const int, int, fptr));
    }
}
