module mach.meta.contains;

private:

/++ Docs: mach.meta.contains

Given at least one argument, `Contains` determines whether
the first template argument is equivalent to any of the
subsequent arguments.

+/

unittest{ /// Example
    static assert(Contains!(int, byte, short, int));
    static assert(!Contains!(int, void, void, void));
}

public:



/// Returns true when the first type is equivalent to any of the successive
/// types, and false otherwise.
/// Returns false when there was one argument or no arguments.
bool Contains(T...)() {
    static if(T.length <= 1) {
        return false;
    }else {
        foreach(Item; T[1 .. $]) {
            static if(
                (is(typeof(T[0] == Item)) && T[0] == Item) ||
                (is(typeof(is(T[0] == Item))) && is(T[0] == Item))
            ) {
                return true;
            }
        }
        return false;
    }
}


unittest { /// Test with zero arguments
    static assert(!Contains!());
}

unittest { /// Test with types
    static assert(Contains!(int, int));
    static assert(Contains!(int, int, int));
    static assert(Contains!(int, int, void));
    static assert(Contains!(int, void, int));
    static assert(Contains!(int, void, void, int));
    static assert(!Contains!(int));
    static assert(!Contains!(int, void));
    static assert(!Contains!(int, void, void));
}

unittest { /// Test with constants
    static assert(Contains!(0, 0));
    static assert(Contains!(0, 0, 0));
    static assert(Contains!(0, 0, 1));
    static assert(Contains!(0, 1, 0));
    static assert(Contains!(0, 1, 1, 0));
    static assert(Contains!(0, 1, void, 0));
    static assert(!Contains!(0));
    static assert(!Contains!(0, 1));
    static assert(!Contains!(0, void));
    static assert(!Contains!(0, 1, void));
}

unittest { /// Test with mixed types and constants
    static assert(Contains!(0, int, 0));
    static assert(!Contains!(0, int, 1));
    static assert(Contains!(int, int, 0));
    static assert(!Contains!(int, short, 1));
}
