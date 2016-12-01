module mach.traits.type;

private:

//

public:



/// True when the symbol is the given type, or is an instance of the given type.
template isType(Type, alias symbol){
    static if(is(typeof(symbol))){
        enum bool isType = is(typeof(symbol) == Type);
    }else{
        enum bool isType = is(symbol == Type);
    }
}

/// ditto
template isType(Type, symbol){
    enum bool isType = is(symbol : Type);
}



version(unittest){
    private:
    class BaseClass{}
    class SubClass: BaseClass{}
}
unittest{
    static assert(isType!(int, int(0)));
    static assert(isType!(int, int(1)));
    static assert(isType!(int, int));
    static assert(isType!(typeof(null), null));
    static assert(isType!(typeof(null), typeof(null)));
    static assert(isType!(string, ""));
    static assert(isType!(string, string));
    static assert(!isType!(int, long(0)));
    static assert(!isType!(string, 0));
}
unittest{
    static assert(isType!(BaseClass, BaseClass));
    static assert(isType!(BaseClass, SubClass));
    static assert(isType!(SubClass, SubClass));
    static assert(!isType!(SubClass, BaseClass));
}
