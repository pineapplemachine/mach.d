module mach.traits.call.callable;

private:

import mach.traits.call.func;
import mach.traits.call.opcall;

public:



/// Determine whether a type is callable. This includes functions, delegates,
/// and classes and structs implementing opCall.
template isCallable(Tx...) if(Tx.length == 1){
    enum bool isCallable = !is(CallableType!Tx == void);
}

/// Get the type of some callable, including functions, delegates, and types
/// implementing opCall. Returns void when the type is not callable according to
/// those critera.
template CallableType(Tx...) if(Tx.length == 1){
    alias T = Tx[0];
    static if(is(FunctionType!T F) && !is(F == void)){
        alias CallableType = F;
    }else static if(is(OpCallType!T O) && !is(O == void)){
        alias CallableType = O;
    }else{
        alias CallableType = void;
    }
}



/// Determine whether some type can be called with the given argument types.
/// The final argument is the callable, and all previous arguments are the
/// types to try calling the callable with.
template isCallableWith(T...) if(T.length){
    alias func = T[$-1];
    alias Args = T[0 .. $-1];
    enum bool isCallableWith = is(typeof((){Args args = Args.init; func(args);}));
}



unittest{
    int x;
    int call1(){return 0;}
    void call2(){}
    static void call3(){}
    struct call4{static void opCall(int){}}
    void function(int) call5;
    void delegate(int) call6;
    static assert(isCallable!(typeof(call1)));
    static assert(isCallable!call1);
    static assert(isCallable!call2);
    static assert(isCallable!call3);
    static assert(isCallable!call4);
    static assert(isCallable!call5);
    static assert(isCallable!call6);
    static assert(is(CallableType!call1 == typeof(call1)));
    static assert(is(CallableType!call2 == typeof(call2)));
    static assert(is(CallableType!call3 == typeof(call3)));
    static assert(is(CallableType!call4 == typeof(call4.opCall)));
    //static assert(is(CallableType!call5 == typeof(call5))); // TODO: Doesn't work
    static assert(is(CallableType!call6 == typeof(call6)));
}

unittest{
    void fn1(){}
    void fn2(int x){}
    int fn3(){return 0;}
    int fn4(int x){return 0;}
    static assert(isCallableWith!(fn1));
    static assert(isCallableWith!(typeof(fn1)));
    static assert(isCallableWith!(int, fn2));
    static assert(isCallableWith!(fn3));
    static assert(isCallableWith!(int, fn4));
    static assert(!isCallableWith!(int, fn1));
    static assert(!isCallableWith!(int, int, fn1));
    static assert(!isCallableWith!(fn2));
    static assert(!isCallableWith!(int, int, fn2));
    static assert(!isCallableWith!(void));
    static assert(!isCallableWith!(int));
    static assert(!isCallableWith!(void, int));
    static assert(!isCallableWith!(int, void));
}
unittest{
    int function(int x) fptr;
    int delegate(int x) del;
    static assert(isCallableWith!(int, fptr));
    static assert(isCallableWith!(int, del));
    static assert(!isCallableWith!(fptr));
    static assert(!isCallableWith!(del));
    static assert(!isCallableWith!(string, fptr));
    static assert(!isCallableWith!(string, del));
}
unittest{
    alias del0 = int delegate(ref int);
    alias del1 = int delegate(ref int) @system;
    alias del2 = int delegate(ref int) pure @nogc;
    static assert(isCallableWith!(int, del0));
    static assert(isCallableWith!(int, del1));
    static assert(isCallableWith!(int, del2));
}
unittest{
    struct OneCall{static void opCall(int x){}}
    struct TwoCalls{static void opCall(int x){} static void opCall(int x, int y){}}
    static assert(isCallableWith!(int, OneCall));
    static assert(isCallableWith!(int, TwoCalls));
    static assert(isCallableWith!(int, int, TwoCalls));
    static assert(!isCallableWith!(OneCall));
    static assert(!isCallableWith!(int, int, OneCall));
    static assert(!isCallableWith!(TwoCalls));
    static assert(!isCallableWith!(string, TwoCalls));
}
