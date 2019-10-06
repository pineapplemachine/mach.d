module mach.meta.varmap;

private:

import mach.types.tuple : tuple;
import mach.meta.ctint : ctint;

/++ Docs

Performs the
[map higher-order function](https://en.wikipedia.org/wiki/Map_(higher-order_function))
for inputs passed as a sequence of variadic arguments.

Given a sequence of variadic arguments, `varmap` returns a tuple containing the
result of each argument being transformed by a passed function.

+/

unittest { /// Example
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

unittest { /// Example
    alias func = (index, element) => (index + element);
    assert(varmapi!func(1, 1, 1) == tuple(1, 2, 3));
}

/++ Docs

Alternatively, the `varmaprange` function can be used when the only
thing that's important is the index.
It accepts either an inclusive low and exclusive high bound, or only
an exclusive high bound with an implicit zero low bound, and it doesn't
accept any value argument list like `varmap` or `varmapi`.

+/

unittest { /// Example
    alias func = (index) => (index * index);
    assert(varmaprange!(4, func) == tuple(0, 1, 4, 9));
    assert(varmaprange!(-2, +3, func) == tuple(4, 1, 0, 1, 4));
}

public:



private string VarMapMixin(in size_t args) {
    string codegen = ``;
    foreach(i; 0 .. args) {
        if(i != 0) codegen ~= `, `;
        codegen ~= `transform(args[` ~ ctint(i) ~ `])`;
    }
    return `return tuple(` ~ codegen ~ `);`;
}

private string VarMapIndexMixin(in size_t args) {
    string codegen = ``;
    foreach(i; 0 .. args) {
        if(i != 0) codegen ~= `, `;
        immutable istr = ctint(i);
        codegen ~= `transform(` ~ istr ~ `, args[` ~ istr ~ `])`;
    }
    return `return tuple(` ~ codegen ~ `);`;
}

private string VarMapRangeMixin(T)(in T low, in T high) {
    string codegen = ``;
    for(T i = low; i < high; i++) {
        if(codegen.length != 0) codegen ~= `, `;
        immutable istr = ctint(i);
        codegen ~= `transform(` ~ istr ~ `)`;
    }
    return `return tuple(` ~ codegen ~ `);`;
}



/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
auto varmap(alias transform, Args...)(auto ref Args args) {
    mixin(VarMapMixin(Args.length));
}

/// Perform a transformation upon each passed argument and return the results
/// as a tuple.
/// The tranformation function should accept two arguments for this function,
/// the first argument will be the index and the second argument will be the
/// value.
auto varmapi(alias transform, Args...)(auto ref Args args) {
    mixin(VarMapIndexMixin(Args.length));
}

/// Perform a transformation upon the range of integers
/// from 0 to the given exclusive high value.
auto varmaprange(size_t high, alias transform)() {
    mixin(VarMapRangeMixin(0, high));
}

/// Perform a transformation upon the range of integers
/// from the given inclusive low to exclusive high values.
auto varmaprange(long low, long high, alias transform)() {
    mixin(VarMapRangeMixin(low, high));
}



unittest { /// Empty varmap
    auto values = varmap!(e => e)();
    static assert(values.length == 0);
}

unittest { /// Non-empty varmap
    auto values = varmap!(e => e + 1)(int(0), uint(1), float(2));
    static assert(is(typeof(values[0]) == int));
    static assert(is(typeof(values[1]) == uint));
    static assert(is(typeof(values[2]) == float));
    assert(values[0] == 1);
    assert(values[1] == 2);
    assert(values[2] == 3);
}

unittest { /// Empty varmapi
    auto values = varmapi!((i, e) => e)();
    static assert(values.length == 0);
}

unittest { /// Single element varmapi
    auto values = varmapi!((i, e) => i + e)(1);
    static assert(values.length == 1);
    assert(values[0] == 1);
}

unittest { /// Multiple element varmapi
    auto values = varmapi!((i, e) => i + e)(1, 1);
    static assert(values.length == 2);
    assert(values[0] == 1);
    assert(values[1] == 2);
}

unittest { /// Empty varmaprange
    auto valuesh = varmaprange!(0, e => e)();
    static assert(valuesh.length == 0);
    auto valueslh0 = varmaprange!(0, 0, e => e)();
    static assert(valueslh0.length == 0);
    auto valueslh1 = varmaprange!(1, 1, e => e)();
    static assert(valueslh1.length == 0);
}

unittest { /// Non-empty varmaprange with only a high bound
    auto values = varmaprange!(2, e => -(cast(int) e))();
    assert(values[0] == 0);
    assert(values[1] == -1);
}

unittest { /// Non-empty varmaprange with a low and high bound
    auto values = varmaprange!(2, 4, e => -(cast(int) e))();
    assert(values[0] == -2);
    assert(values[1] == -3);
}
