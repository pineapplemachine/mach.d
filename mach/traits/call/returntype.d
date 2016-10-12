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
    static if(is(R == void)){
        enum bool Returns = is(ReturnType!T == void);
    }else{
        enum bool Returns = is(typeof({
            ReturnType!T x; auto y = x;
        }));
    }
}



/// Determine whether some callable returns a value of the given type.
template ReturnsExactly(R, T...){
    enum bool ReturnsExactly = is(ReturnType!T == R);
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
        static assert(!ReturnsExactly!(int, int));
    }{
        static assert(Returns!(void, fn1));
        static assert(Returns!(void, typeof(fn1)));
        static assert(Returns!(int, fn2));
        static assert(Returns!(string, {return "";}));
        static assert(!Returns!(int, fn1));
        static assert(!Returns!(int, int));
    }{
        static assert(!ReturnsExactly!(long, fn2));
        static assert(!ReturnsExactly!(const int, fn2));
        static assert(Returns!(long, fn2));
        static assert(Returns!(const int, fn2));
    }
}
