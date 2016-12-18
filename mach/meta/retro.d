module mach.meta.retro;

private:

import mach.meta.aliases : Aliases;

public:



/// Get a sequence with the items in reverse order.
template Retro(T...){
    static if(T.length <= 1){
        alias Retro = T;
    }else{
        alias Retro = Aliases!(Retro!(T[1 .. $]), T[0]);
    }
}



unittest{
    import mach.meta : Aliases;
    static assert(is(Retro!() == Aliases!()));
    static assert(is(Retro!(int) == Aliases!(int)));
    static assert(is(Retro!(int, int) == Aliases!(int, int)));
    static assert(is(Retro!(int, string) == Aliases!(string, int)));
    static assert(is(Retro!(int, string, void) == Aliases!(void, string, int)));
    static assert(Retro!(0) == Aliases!(0));
    static assert(Retro!(0, 0) == Aliases!(0, 0));
    static assert(Retro!(0, 1) == Aliases!(1, 0));
    static assert(Retro!(0, 1, 2) == Aliases!(2, 1, 0));
}
