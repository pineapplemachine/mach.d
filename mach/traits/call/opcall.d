module mach.traits.call.opcall;

private:

//

public:



/// Get whether the given type is a class or struct implementing opCall as
/// either an instance or static method.
template hasOpCall(Tx...) if(Tx.length == 1){
    enum bool hasOpCall = !is(OpCallType!(Tx[0]) == void);
}

/// Get the type of some callable function belonging to a type that implements
/// opCall.
template OpCallType(alias T){
    alias OpCallType = OpCallType!(typeof(T));
}
/// ditto
template OpCallType(T){
    static if(is(typeof(&T.opCall) U == delegate)){
        alias OpCallType = U; // Object with member function opCall
    }else static if(is(typeof(&T.opCall) V : V*) && is(V == function)){
        alias OpCallType = V; // Type with static member function opCall
    }else{
        alias OpCallType = void;
    }
}



unittest{
    struct InstanceCallStruct{void opCall(){}}
    struct StaticCallStruct{static void opCall(){}}
    struct NoCallStruct{}
    class InstanceCallClass{void opCall(){}}
    class StaticCallClass{static void opCall(){}}
    class NoCallClass{}
    static assert(hasOpCall!InstanceCallStruct);
    static assert(hasOpCall!StaticCallStruct);
    static assert(hasOpCall!InstanceCallClass);
    static assert(hasOpCall!StaticCallClass);
    static assert(is(OpCallType!InstanceCallStruct == typeof(InstanceCallStruct.opCall)));
    static assert(is(OpCallType!StaticCallStruct == typeof(StaticCallStruct.opCall)));
    static assert(!hasOpCall!NoCallStruct);
    static assert(!hasOpCall!NoCallClass);
    static assert(!hasOpCall!int);
    static assert(!hasOpCall!string);
    static assert(!hasOpCall!hasOpCall);
}
unittest{
    struct InstanceCall{int opCall(int){return 0;}}
    struct StaticCall{static int opCall(int){return 0;}}
    static assert(hasOpCall!InstanceCall);
    static assert(hasOpCall!StaticCall);
    static assert(is(OpCallType!InstanceCall == typeof(InstanceCall.opCall)));
    static assert(is(OpCallType!StaticCall == typeof(StaticCall.opCall)));
}
