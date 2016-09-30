module mach.meta.varfilter;

private:

import mach.types : tuple;

public:



template canVarFilter(alias pred, T...){
    static if(T.length == 0){
        enum bool canVarFilter = true;
    }else static if(T.length == 1){
        enum bool canVarFilter = is(typeof({
            static if(pred!T){}
        }));
    }else{
        enum bool canVarFilter = (
            canVarFilter!(pred, T[0]) &&
            canVarFilter!(pred, T[1 .. $])
        );
    }
}

/// Return as a tuple only those arguments whose types meet a predicate
/// template.
auto varfilter(alias pred, T...)(auto ref T args) if(canVarFilter!(pred, T)){
    static if(T.length == 0){
        return tuple();
    }else static if(T.length == 1){
        static if(pred!T){
            return tuple(args);
        }else{
            return tuple();
        }
    }else{
        auto rest = varfilter!pred(args[1 .. $]);
        static if(pred!(T[0])){
            return tuple(args[0], rest.expand);
        }else{
            return rest;
        }
    }
}



version(unittest){
    enum bool isInt(T) = is(T == int);
}
unittest{
    static assert(canVarFilter!(isInt));
    static assert(canVarFilter!(isInt, int));
    static assert(canVarFilter!(isInt, int, string, double));
}
unittest{
    auto values = varfilter!isInt();
    static assert(values.length == 0);
}
unittest{
    auto values = varfilter!isInt(float(0));
    static assert(values.length == 0);
}
unittest{
    auto values = varfilter!isInt(int(0), uint(0), int(1), float(0));
    static assert(values.length == 2);
    assert(values[0] == 0);
    assert(values[1] == 1);
}
