module mach.traits.parameters;

private:

import std.traits : Parameters;

public:



template getFunctionWithMostParameters(Agg, string name){
    alias getFunctionWithMostParameters = getFunctionWithMostParameters!(
        __traits(getOverloads, Agg, name)
    );
}

private template getFunctionWithMostParameters(overloads...){
    alias getFunctionWithMostParameters = getFunctionWithCompParameters!(
        `>`, overloads
    );
}


template getFunctionWithLeastParameters(Agg, string name){
    alias getFunctionWithLeastParameters = getFunctionWithLeastParameters!(
        __traits(getOverloads, Agg, name)
    );
}

private template getFunctionWithLeastParameters(overloads...){
    alias getFunctionWithLeastParameters = getFunctionWithCompParameters!(
        `<`, overloads
    );
}



template getFunctionWithCompParameters(string comparison, overloads...){
    static if(overloads.length == 0){
        alias getFunctionWithCompParameters = void;
    }else static if(overloads.length == 1){
        alias getFunctionWithCompParameters = overloads[0];
    }else{
        mixin(`
            enum bool branch = (
                Parameters!(overloads[0]).length ` ~ comparison ~ ` 
                Parameters!(overloads[1]).length
            );
        `);
        static if(branch){
            static if(overloads.length > 2){
                alias getFunctionWithCompParameters = getFunctionWithCompParameters!(
                    comparison, overloads[0], overloads[2 .. $]
                );
            }else{
                alias getFunctionWithCompParameters = overloads[0];
            }
        }else{
            static if(overloads.length > 2){
                alias getFunctionWithCompParameters = getFunctionWithCompParameters!(
                    comparison, overloads[1], overloads[2 .. $]
                );
            }else{
                alias getFunctionWithCompParameters = overloads[1];
            }
        }
    }
}



version(unittest){
    private:
    struct OverloadTest{
        this(int x){}
        this(int x, int y){}
        this(int x, int y, int z){}
        auto foo(int x, int y){}
        auto foo(int x, int y, int z, int w){}
    }
}
unittest{
    static assert(
        Parameters!(getFunctionWithMostParameters!(OverloadTest, `__ctor`)).length == 3
    );
    static assert(
        Parameters!(getFunctionWithLeastParameters!(OverloadTest, `__ctor`)).length == 1
    );
    static assert(
        Parameters!(getFunctionWithMostParameters!(OverloadTest, `foo`)).length == 4
    );
    static assert(
        Parameters!(getFunctionWithLeastParameters!(OverloadTest, `foo`)).length == 2
    );
}
