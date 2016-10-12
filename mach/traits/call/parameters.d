module mach.traits.call.parameters;

private:

import mach.traits.call.callable;

public:



template Parameters(T...) if(T.length == 1 && isCallable!T){
    static if(is(CallableType!T P == function)){
        alias Parameters = P;
    }else static if(is(CallableType!T P == delegate)){
        alias Parameters = Parameters!P;
    }else{
        static assert(false, "Unable to get parameter types.");
    }
}



version(unittest){
    private:
    import mach.meta.aliases : Aliases;
}
unittest{
    static void sfunc(){}
    void fn1(){}
    void fn2(){}
    void function() fptr;
    void delegate() del;
    auto fn1ptr = &fn1;
    static assert(is(Parameters!sfunc == Aliases!()));
    static assert(is(Parameters!fn1 == Aliases!()));
    static assert(is(Parameters!fn2 == Aliases!()));
    static assert(is(Parameters!fptr == Aliases!()));
    static assert(is(Parameters!del == Aliases!()));
    static assert(is(Parameters!fn1ptr == Aliases!()));
}
unittest{
    static void sfunc(int x){}
    void fn1(int x){}
    void fn2(int x){}
    void function(int x) fptr;
    void delegate(int x) del;
    auto fn1ptr = &fn1;
    static assert(is(Parameters!sfunc == Aliases!(int)));
    static assert(is(Parameters!fn1 == Aliases!(int)));
    static assert(is(Parameters!fn2 == Aliases!(int)));
    static assert(is(Parameters!fptr == Aliases!(int)));
    static assert(is(Parameters!del == Aliases!(int)));
    static assert(is(Parameters!fn1ptr == Aliases!(int)));
}
unittest{
    static void sfunc(uint x, ulong y){}
    void fn1(uint x, ulong y){}
    void fn2(uint x, ulong y){}
    void function(uint x, ulong y) fptr;
    void delegate(uint x, ulong y) del;
    auto fn1ptr = &fn1;
    static assert(is(Parameters!sfunc == Aliases!(uint, ulong)));
    static assert(is(Parameters!fn1 == Aliases!(uint, ulong)));
    static assert(is(Parameters!fn2 == Aliases!(uint, ulong)));
    static assert(is(Parameters!fptr == Aliases!(uint, ulong)));
    static assert(is(Parameters!del == Aliases!(uint, ulong)));
    static assert(is(Parameters!fn1ptr == Aliases!(uint, ulong)));
}

