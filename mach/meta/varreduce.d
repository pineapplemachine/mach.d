module mach.meta.varreduce;

private:

import mach.meta.ctint : ctint;

/++ Docs

Provides an implementation of the
[reduce higher-order function](https://en.wikipedia.org/wiki/Fold_(higher-order_function)),
operating upon a sequence of variadic arguments.

The reduction operation can be given a seed by prepending the seed as an
additional argument.

+/

unittest{ /// Example
    alias summod2 = (a, b) => (a + (b % 2));
    assert(varreduce!summod2(0, 1, 2, 3) == 2);
}

/++ Docs

The module also provides some common abstractions of the reduce function.

+/

unittest{ /// Example
    assert(varmin(1, 2, 3) == 1); // Minimum
    assert(varmax(1, 2, 3) == 3); // Maximum
}

unittest{ /// Example
    assert(varsum(1, 2, 3, 4) == 10); // Sum
    assert(varproduct(1, 2, 3, 4) == 24); // Product
}

public:



/// Mixin to generate code for `varreduce`.
/// e.g. `return func(func(func(args[0], args[1]), args[2]), args[3]);`
private string VarReduceMixin(in size_t args){
    string codegen = `args[0]`;
    foreach(i; 1 .. args){
        codegen = `func(` ~ codegen ~ `, args[` ~ ctint(i) ~ `])`;
    }
    return `return ` ~ codegen ~ `;`;
}

/// Mixin to generate code for `varmin` and `varmax`.
/// e.g. `return args[0] < args[1] ? args[0] : args[1];`
private string VarMinMaxMixin(in string op, in size_t args){
    string branch(in size_t a, in size_t b){
        immutable arga = `args[` ~ ctint(a) ~ `]`;
        immutable argb = `args[` ~ ctint(b) ~ `]`;
        immutable cond = arga ~ ` ` ~ op ~ ` ` ~ argb;
        if(b >= args - 1){
            return cond ~ ` ? ` ~ arga ~ ` : ` ~ argb;
        }else{
            return cond ~ ` ? (` ~ branch(a, b + 1) ~ `) : (` ~ branch(b, b + 1) ~ `)`;
        }
    }
    return `return ` ~ branch(0, 1) ~ `;`;
}

/// Mixin to generate code for `varsum` and `varproduct`.
/// e.g. `return args[0] + args[1] + args[2] + args[3];`
private string VarSumProductMixin(in string op, in size_t args){
    string codegen = ``;
    foreach(i; 0 .. args){
        if(i != 0) codegen ~= ` ` ~ op ~ ` `;
        codegen ~= `args[` ~ ctint(i) ~ `]`;
    }
    return `return ` ~ codegen ~ `;`;
}



/// Implements the reduce higher-order function for variadic arguments.
auto varreduce(alias func, Args...)(auto ref Args args){
    static assert(Args.length > 0, "Cannot reduce an empty sequence.");
    mixin(VarReduceMixin(Args.length));
}



/// Get the least value of the passed arguments.
auto varmin(Args...)(auto ref Args args){
    static assert(Args.length > 0, "Cannot find the minimum of an empty sequence.");
    static if(Args.length == 1){
        return args[0];
    }else{
        mixin(VarMinMaxMixin(`<`, Args.length));
    }
}

/// Get the greatest value of the passed arguments.
auto varmax(Args...)(auto ref Args args){
    static assert(Args.length > 0, "Cannot find the maximum of an empty sequence.");
    static if(Args.length == 1){
        return args[0];
    }else{
        mixin(VarMinMaxMixin(`>=`, Args.length));
    }
}

/// Get the sum of the passed arguments.
auto varsum(Args...)(auto ref Args args){
    mixin(VarSumProductMixin(`+`, Args.length));
}

/// Get the product of the passed arguments.
auto varproduct(Args...)(auto ref Args args){
    mixin(VarSumProductMixin(`*`, Args.length));
}

/// Get the number of arguments which evaluate true.
auto varcount(Args...)(auto ref Args args){
    size_t count = 0;
    foreach(i, _; Args) count += cast(bool) args[i];
    return count;
}



unittest{
    assert(varmin(0) == 0);
    assert(varmin(0, 1, 2, 3) == 0);
    assert(varmin(3, 2, 1) == 1);
}
unittest{
    assert(varmax(0) == 0);
    assert(varmax(0, 1, 2, 3) == 3);
    assert(varmax(3, 2, 1) == 3);
}
unittest{
    assert(varsum(0) == 0);
    assert(varsum(0, 1, 2, 3) == 6);
    assert(varsum(3, 2, 1) == 6);
}
unittest{
    assert(varproduct(0) == 0);
    assert(varproduct(0, 1, 2, 3) == 0);
    assert(varproduct(3, 2, 1) == 6);
}
unittest{
    assert(varcount() == 0);
    assert(varcount(0) == 0);
    assert(varcount(1) == 1);
    assert(varcount(0, 1) == 1);
    assert(varcount(1, 2, 3, 0) == 3);
    assert(varcount(1, 2, 3, null) == 3);
}
