module mach.meta.varselect;

private:

/++ Docs: mach.meta.varselect

The `varselect` function accepts a number as a template argument and at least
one runtime argument.
It returns the argument at the zero-based index indicated by its template argument.
Because the arguments are lazily-evaluated, only the selected argument will
actually be evaluated.

The function will not compile if the index given is outside the bounds of the
argument list.

+/

unittest{ /// Example
    assert(varselect!0(0, 1, 2) == 0);
    assert(varselect!2(0, 1, 2) == 2);
}

unittest{ /// Example
    static assert(!is(typeof({
        varselect!10(0, 1, 2); // Index out of bounds
    })));
}

public:



/// Return the argument at the given index.
/// Arguments are lazy, meaning that those arguments not selected are
/// not evaluated.
auto varselect(size_t i, Args...)(lazy Args args) if(i < Args.length){
    return args[i]();
}



unittest{
    static assert(!is(typeof({varselect!0();})));
    static assert(!is(typeof({varselect!1();})));
    static assert(!is(typeof({varselect!1(0);})));
    assert(varselect!0(0) == 0);
    assert(varselect!0(1, 2) == 1);
    assert(varselect!1(1, 2) == 2);
    assert(varselect!2(1, 2, "hi") == "hi");
}
unittest{
    assert(varselect!false(0, 0) == 0);
    assert(varselect!true(0, 0) == 0);
    assert(varselect!false(0, 1) == 0);
    assert(varselect!true(0, 1) == 1);
}
unittest{
    void x(){}
    void y(){assert(false);}
    varselect!false(x(), y());
    bool error = false;
    try{varselect!true(x(), y());}
    catch(Throwable){error = true;}
    assert(error);
}
