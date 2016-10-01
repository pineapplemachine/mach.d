module mach.meta.filter;

private:

import mach.meta.aliases : Aliases;

public:



template Filter(alias predicate, T...){
    static if(T.length == 0){
        alias Filter = Aliases!();
    }else static if(T.length == 1){
        static if(predicate!(T[0])) alias Filter = T;
        else alias Filter = Aliases!();
    }else{
        alias Filter = Aliases!(
            Filter!(predicate, T[0]),
            Filter!(predicate, T[1 .. $])
        );
    }
}



version(unittest){
    private:
    import mach.traits.primitives : isFloatingPoint, isIntegral;
}
unittest{
    static assert(is(
        Filter!(isFloatingPoint, int, float, long, double) == Aliases!(float, double)
    ));
    static assert(is(
        Filter!(isIntegral, int, float, long, double) == Aliases!(int, long)
    ));
}
