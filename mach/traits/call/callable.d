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
