module mach.meta.varmap;

private:

import mach.types : tuple;

public:



template canVarMap(alias transform, T...){
    static if(T.length == 0){
        enum bool canVarMap = true;
    }else static if(T.length == 1){
        enum bool canVarMap = is(typeof({auto x = transform(T.init);}));
    }else{
        enum bool canVarMap = (
            canVarMap!(transform, T[0]) &&
            canVarMap!(transform, T[1 .. $])
        );
    }
}

template canVarMapIndex(alias transform, T...){
    static if(T.length == 0){
        enum bool canVarMapIndex = true;
    }else static if(T.length == 1){
        enum bool canVarMapIndex = is(typeof({auto x = transform(0, T.init);}));
    }else{
        enum bool canVarMapIndex = (
            canVarMapIndex!(transform, T[0]) &&
            canVarMapIndex!(transform, T[1 .. $])
        );
    }
}

/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
auto varmap(alias transform, T...)(auto ref T args) if(canVarMap!(transform, T)){
    static if(T.length == 0){
        return tuple();
    }else static if(T.length == 1){
        return tuple(transform(args));
    }else{
        auto here = transform(args[0]);
        auto rest = varmap!transform(args[1 .. $]);
        return tuple(here, rest.expand);
    }
}

/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
/// The tranformation function should accept two arguments for this function,
/// the first argument will be the index and the second argument will be the
/// value.
auto varmapi(alias transform, size_t index = 0, T...)(auto ref T args) if(
    canVarMapIndex!(transform, T)
){
    static if(T.length == 0){
        return tuple();
    }else static if(T.length == 1){
        return tuple(transform(index, args));
    }else{
        auto here = transform(index, args[0]);
        auto rest = varmapi!(transform, index + 1)(args[1 .. $]);
        return tuple(here, rest.expand);
    }
}



unittest{
    static assert(canVarMap!((e => e)));
    static assert(canVarMap!((e => e), int));
    static assert(canVarMap!((e => e), int, string, double));
    static assert(!canVarMap!((e => e), void));
    static assert(!canVarMap!((e => e), int, int, void));
}
unittest{
    auto values = varmap!(e => e)();
    static assert(values.length == 0);
}
unittest{
    auto values = varmap!(e => e + 1)(int(0), uint(1), float(2));
    static assert(is(typeof(values[0]) == int));
    static assert(is(typeof(values[1]) == uint));
    static assert(is(typeof(values[2]) == float));
    assert(values[0] == 1);
    assert(values[1] == 2);
    assert(values[2] == 3);
}

unittest{
    auto values = varmapi!((i, e) => e)();
    static assert(values.length == 0);
}
unittest{
    auto values = varmapi!((i, e) => i + e)(1);
    static assert(values.length == 1);
    assert(values[0] == 1);
}
unittest{
    auto values = varmapi!((i, e) => i + e)(1, 1);
    static assert(values.length == 2);
    assert(values[0] == 1);
    assert(values[1] == 2);
}
