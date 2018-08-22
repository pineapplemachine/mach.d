module mach.meta.retro;

private:

import mach.meta.aliases : Aliases;

/++ Docs: mach.meta.retro

Given a sequence of template arguments, the `Retro` template will generate a
new sequence which is the original sequence in reverse order.

+/

unittest{ /// Example
    static assert(is(Retro!(byte, short, int) == Aliases!(int, short, byte)));
}

unittest{ /// Example
    static assert(is(Retro!(int) == Aliases!(int)));
}

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
