module mach.meta.varselect;

private:

//

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
    catch{error = true;}
    assert(error);
}
