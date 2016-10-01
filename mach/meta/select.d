module mach.meta.select;

private:

import mach.meta.aliases : Alias;

public:



/// Aliases to the argument at the given index.
template Select(size_t i, T...) if(i < T.length){
    alias Select = Alias!(T[i]);
}



unittest{
    static assert(!is(typeof(Select!0)));
    static assert(!is(typeof(Select!1)));
    static assert(!is(typeof(Select!(1, int))));
    static assert(is(Select!(0, int) == int));
    static assert(is(Select!(0, int, int) == int));
    static assert(is(Select!(0, int, long) == int));
    static assert(is(Select!(0, long, int) == long));
    static assert(is(Select!(1, int, long) == long));
    static assert(is(Select!(1, long, int) == int));
    static assert(is(Select!(2, long, int, string) == string));
    static assert(is(Select!(2, 'a', 'b', int) == int));
    static assert(Select!(0, 'a', 'b', int) == 'a');
}
unittest{
    static assert(is(Select!(false, int, int) == int));
    static assert(is(Select!(true, int, int) == int));
    static assert(is(Select!(false, int, long) == int));
    static assert(is(Select!(true, int, long) == long));
}
