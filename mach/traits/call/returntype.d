module mach.traits.call.returntype;

private:

import mach.traits.call.callable;

public:



/// Get the return type of some callable type.
template ReturnType(Tx...) if(Tx.length == 1 && isCallable!(Tx[0])){
    static if(is(CallableType!(Tx[0]) R == return)){
        alias ReturnType = R;
    }else{
        static assert(false, "Unable to get return type.");
    }
}



/// Determine whether some callable type returns a value of the given type.
template Returns(alias T, Ret){
    enum bool Returns = Returns!(CallableType!T, Ret);
}
/// ditto
template Returns(T, Ret){
    static if(isCallable!(CallableType!T)){
        enum bool Returns = is(ReturnType!(CallableType!T) == Ret);
    }else{
        enum bool Returns = false;
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
    static assert(Returns!(fn1, void));
    static assert(Returns!(typeof(fn1), void));
    static assert(Returns!(fn2, int));
    static assert(!Returns!(fn1, int));
    static assert(!Returns!(int, int));
}
