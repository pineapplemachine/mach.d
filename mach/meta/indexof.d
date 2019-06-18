module mach.meta.indexof;

private:

/++ Docs: mach.meta.indexof

Given at least one argument, `IndexOf` determines whether
the first template argument is equivalent to any of the
subsequent arguments, and returns the index of that argument
if so. The function returns -1 when the first argument was
missing or when it was not equivalent to any of the successive
arguments.

+/

unittest{ /// Example
    static assert(IndexOf!(int, byte, short, int));
    static assert(IndexOf!(int, void, void, void) == -1);
}

public:



/// Return the zero-based index of the first argument within the list of
/// successive arguments.
/// Returns -1 when there were no arguments, or when the initial argument
/// was not equivalent to any of the successive arguments.
ptrdiff_t IndexOf(T...)() {
    static if(T.length <= 1) {
        return -1;
    }else {
        foreach(i, Item; T[1 .. $]) {
            static if(
                (is(typeof(T[0] == Item)) && T[0] == Item) ||
                (is(typeof(is(T[0] == Item))) && is(T[0] == Item))
            ) {
                return cast(ptrdiff_t) i;
            }
        }
        return -1;
    }
}



unittest { /// Test with zero arguments
    static assert(IndexOf!() == -1);
}

unittest { /// Test with types
    static assert(IndexOf!(int, int) == 0);
    static assert(IndexOf!(int, int, int) == 0);
    static assert(IndexOf!(int, int, void) == 0);
    static assert(IndexOf!(int, void, int) == 1);
    static assert(IndexOf!(int, void, void, int) == 2);
    static assert(IndexOf!(int) == -1);
    static assert(IndexOf!(int, void) == -1);
    static assert(IndexOf!(int, void, void) == -1);
}

unittest { /// Test with constants
    static assert(IndexOf!(0, 0) == 0);
    static assert(IndexOf!(0, 0, 0) == 0);
    static assert(IndexOf!(0, 0, 1) == 0);
    static assert(IndexOf!(0, 1, 0) == 1);
    static assert(IndexOf!(0, 1, 1, 0) == 2);
    static assert(IndexOf!(0, 1, void, 0) == 2);
    static assert(IndexOf!(0) == -1);
    static assert(IndexOf!(0, 1) == -1);
    static assert(IndexOf!(0, void) == -1);
    static assert(IndexOf!(0, 1, void) == -1);
}

unittest { /// Test with mixed types and constants
    static assert(IndexOf!(0, int, 0) == 1);
    static assert(IndexOf!(0, int, 1) == -1);
    static assert(IndexOf!(int, int, 0) == 0);
    static assert(IndexOf!(int, short, 1) == -1);
}
