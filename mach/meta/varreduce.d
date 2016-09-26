module mach.meta.varreduce;

private:

//import mach.traits : CommonType, hasCommonType;

public:



template canVarReduce(alias func, T...){
    static if(T.length == 1){
        enum bool canVarReduce = true;
    }else static if(T.length >= 2){
        static if(is(typeof({
            auto acc = func(T[0].init, T[1].init);
        }))){
            static if(T.length == 2){
                enum bool canVarReduce = true;
            }else{
                enum bool canVarReduce = canVarReduce!(
                    func, typeof(func(T[0].init, T[1].init)), T[2 .. $]
                );
            }
        }else{
            enum bool canVarReduce = false;
        }
    }else{
        enum bool canVarReduce = false;
    }
}

auto varreduce(alias func, T...)(auto ref T args) if(canVarReduce!(func, T)){
    static if(T.length == 1){
        return args[0];
    }else static if(T.length == 2){
        return func(args[0], args[1]);
    }else{
        return varreduce!func(func(args[0], args[1]), args[2 .. $]);
    }
}



alias VarReduceMin = (a, b) => (a < b ? a : b);
alias VarReduceMax = (a, b) => (a > b ? a : b);
alias VarReduceSum = (a, b) => (a + b);
alias VarReduceProduct = (a, b) => (a * b);
alias VarReduceAll = (a, b) => (a && b);
alias VarReduceAny = (a, b) => (a || b);
alias VarReduceCount = (a, b) => (a + (b ? 1 : 0));

/// Get the least value of the passed arguments.
auto varmin(T...)(auto ref T args) if(canVarReduce!(VarReduceMin, T)){
    return varreduce!VarReduceMin(args);
}

/// Get the greatest value of the passed arguments.
auto varmax(T...)(auto ref T args) if(canVarReduce!(VarReduceMax, T)){
    return varreduce!VarReduceMax(args);
}

/// Get the sum of the passed arguments.
auto varsum(T...)(auto ref T args) if(canVarReduce!(VarReduceSum, T)){
    return varreduce!VarReduceSum(args);
}

/// Get the product of the passed arguments.
auto varproduct(T...)(auto ref T args) if(canVarReduce!(VarReduceProduct, T)){
    return varreduce!VarReduceProduct(args);
}

/// Get whether any passed arguments evaluate true.
auto varany(T...)(auto ref T args) if(canVarReduce!(VarReduceAny, T)){
    return varreduce!VarReduceAny(args);
}

/// Get whether all passed arguments evaluate true.
auto varall(T...)(auto ref T args) if(canVarReduce!(VarReduceAll, T)){
    return varreduce!VarReduceAll(args);
}

/// Get the number of arguments which evaluate true.
auto varcount(T...)(auto ref T args) if(T.length == 0 || canVarReduce!(VarReduceCount, size_t, T)){
    static if(T.length == 0){
        return size_t(0);
    }else{
        return varreduce!VarReduceCount(size_t(0), args);
    }
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
    assert(varany(true));
    assert(varany(true, true, true));
    assert(varany(true, true, false));
    assert(!varany(false));
    assert(!varany(null));
}
unittest{
    assert(varall(true));
    assert(varall(true, true, true));
    assert(!varall(false));
    assert(!varall(true, true, false));
    assert(!varall(true, true, false, null));
}
unittest{
    assert(varcount() == 0);
    assert(varcount(0) == 0);
    assert(varcount(1) == 1);
    assert(varcount(0, 1) == 1);
    assert(varcount(1, 2, 3, 0) == 3);
    assert(varcount(1, 2, 3, null) == 3);
}
