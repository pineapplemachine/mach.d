module mach.meta.varmap;

private:

import mach.types : tuple;
import mach.text.numeric : writeint;

/++ Docs

Performs the
[map higher-order function](https://en.wikipedia.org/wiki/Map_(higher-order_function))
for inputs passed as a sequence of variadic arguments.

Given a sequence of variadic arguments, `varmap` returns a tuple containing the
result of each argument being transformed by a passed function.

+/

unittest{ /// Example
    assert(varmap!(e => e + 1)(0, 1, 2) == tuple(1, 2, 3));
}

/++ Docs

The module also provides a `varmapi` function, which passes the zero-based
index of the argument being mapped to the transformation function,
in addition to the element being transformed.

There is additionally a `varmapis` function which accepts as its template
argument a templated function taking the index as a template argument and
the value as a runtime argument.

+/

unittest{ /// Example
    alias func = (index, element) => (index + element);
    assert(varmapi!func(1, 1, 1) == tuple(1, 2, 3));
}

public:



private string VarMapMixin(in size_t args){
    string codegen = ``;
    foreach(i; 0 .. args){
        if(i != 0) codegen ~= `, `;
        codegen ~= `transform(args[` ~ writeint(i) ~ `])`;
    }
    return `return tuple(` ~ codegen ~ `);`;
}

private string VarMapIndexMixin(in size_t args){
    string codegen = ``;
    foreach(i; 0 .. args){
        if(i != 0) codegen ~= `, `;
        immutable istr = writeint(i);
        codegen ~= `transform(` ~ istr ~ `, args[` ~ istr ~ `])`;
    }
    return `return tuple(` ~ codegen ~ `);`;
}


/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
auto varmap(alias transform, Args...)(auto ref Args args){
    mixin(VarMapMixin(Args.length));
}

/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
/// The tranformation function should accept two arguments for this function,
/// the first argument will be the index and the second argument will be the
/// value.
auto varmapi(alias transform, size_t index = 0, Args...)(auto ref Args args){
    mixin(VarMapIndexMixin(Args.length));
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
