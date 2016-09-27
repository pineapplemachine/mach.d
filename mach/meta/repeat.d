module mach.meta.repeat;

private:

import mach.meta.aliases : Aliases;

public:



/// Repeat a list of aliases some given number of times.
template Repeat(size_t count, T...){
    static if(count == 0 || T.length == 0){
        alias Repeat = Aliases!();
    }else static if(count == 1){
        alias Repeat = T;
    }else{
        alias Repeat = Aliases!(T, Repeat!(count - 1, T));
    }
}



unittest{
    static assert(is(Repeat!(0) == Aliases!()));
    static assert(is(Repeat!(1) == Aliases!()));
    static assert(is(Repeat!(0, int, long) == Aliases!()));
    static assert(is(Repeat!(1, int, long) == Aliases!(int, long)));
    static assert(is(Repeat!(2, int, long) == Aliases!(int, long, int, long)));
    static assert(is(Repeat!(3, int, long) == Aliases!(int, long, int, long, int, long)));
}
