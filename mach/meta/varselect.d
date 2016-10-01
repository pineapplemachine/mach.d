module mach.meta.select;

private:

//

public:



/// Return the argument at the given index.
auto varselect(size_t i, Args...)(auto ref Args args) if(i < Args.length){
    return args[i];
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
