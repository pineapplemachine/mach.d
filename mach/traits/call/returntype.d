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
