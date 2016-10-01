module mach.meta.map;

private:

import mach.meta.aliases : Aliases;

public:



template Map(alias transform, T...){
    static if(T.length == 0){
        alias Map = Aliases!();
    }else static if(T.length == 1){
        alias Map = Aliases!(transform!(T[0]));
    }else{
        alias Map = Aliases!(
            Map!(transform, T[0]),
            Map!(transform, T[1 .. $])
        );
    }
}



version(unittest){
    private:
    import mach.traits.primitives : isIntegral;
    template Embiggen(T){
        static if(is(T == int)){
            alias Embiggen = long;
        }else static if(is(T == float)){
            alias Embiggen = double;
        }else{
            alias Embiggen = T;
        }
    }
}
unittest{
    static assert(is(
        Map!(Embiggen, int, float, double) == Aliases!(long, double, double)
    ));
    alias integrals = Map!(isIntegral, int, float, double);
    static assert(integrals.length == 3);
    static assert(integrals[0] == true);
    static assert(integrals[1] == false);
    static assert(integrals[2] == false);
}
