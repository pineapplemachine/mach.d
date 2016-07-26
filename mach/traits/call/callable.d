module mach.traits.call.callable;

private:

import mach.traits.call.func;
import mach.traits.call.opcall;

public:



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
