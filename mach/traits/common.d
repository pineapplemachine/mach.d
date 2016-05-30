module mach.traits.common;

private:

//

public:



template hasCommonType(T...){
    static if(T.length == 0){
        enum bool hasCommonType = true;
    }else static if(T.length == 1){
        enum bool hasCommonType = is(typeof(T[0].init));
    }else static if(is(typeof(true ? T[0].init : T[1].init) Common)){
        static if(T.length > 2){
            alias hasCommonType = hasCommonType!(Common, T[2 .. $]);
        }else{
            enum bool hasCommonType = true;
        }
    }else{
        enum bool hasCommonType = false;
    }
}

template CommonType(T...) if(hasCommonType!T && T.length){
    static if(T.length == 1){
        alias CommonType = T[0];
    }else static if(T.length > 1){
        alias CommonType = CommonType!(typeof(true ? T[0].init : T[1].init), T[2 .. $]);
    }else{
        alias CommonType = void;
    }
}



version(unittest){
    private:
    class BaseClass{}
    class SubClassA : BaseClass {}
    class SubClassB : BaseClass {}
}
unittest{
    // hasCommonType
    static assert(hasCommonType!(int));
    static assert(hasCommonType!(int, int));
    static assert(hasCommonType!(byte, ubyte, short, ushort, int, uint, long, ulong, real, double, float));
    static assert(hasCommonType!(BaseClass, SubClassA));
    static assert(hasCommonType!(BaseClass, SubClassB));
    static assert(hasCommonType!(SubClassA, SubClassB));
    static assert(hasCommonType!(BaseClass, SubClassA, SubClassB));
    static assert(!hasCommonType!(BaseClass, double));
    // CommonType
    static assert(is(CommonType!(real, byte) == real));
    static assert(is(CommonType!(BaseClass, SubClassA) == BaseClass));
    static assert(is(CommonType!(BaseClass, SubClassB) == BaseClass));
    static assert(is(CommonType!(SubClassA, SubClassB) == BaseClass));
    static assert(is(CommonType!(BaseClass, SubClassA, SubClassB) == BaseClass));
}
