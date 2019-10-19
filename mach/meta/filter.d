module mach.meta.filter;

private:

import mach.meta.aliases : Aliases;
import mach.meta.ctint : ctint;

/++ Docs: mach.meta.filter

Given a sequence of values, `Filter` generates a new sequence containing
only those values which meet a predicate.

The first template argument must be a predicate,
and subsequent arguments constitute the sequence to be filtered.

+/

unittest { /// Example
    enum bool NotVoid(T) = !is(T == void);
    static assert(is(Filter!(NotVoid, void, int, void, long) == Aliases!(int, long)));
}

unittest { /// Example
    enum bool isInt(T) = is(T == int);
    static assert(is(Filter!(isInt, double, float, long) == Aliases!()));
}

public:



private string FilterMixin(in size_t args) {
    string aliasDecls = ``;
    string aliasArgs = ``;
    foreach(i; 0 .. args) {
        if(i != 0) aliasArgs ~= `, `;
        const istr = ctint(i);
        aliasDecls ~= (
            `static if(predicate!(T[` ~ istr ~ `])) ` ~
            `alias F` ~ istr ~ ` = Aliases!(T[` ~ istr ~ "]);\n" ~
            `else alias F` ~ istr ~ " = Aliases!();\n"
        );
        aliasArgs ~= `F` ~ istr;
    }
    return aliasDecls ~ `alias Filter = Aliases!(` ~ aliasArgs ~ `);`;
}

template Filter(alias predicate, T...){
    static if(T.length == 0) {
        alias Filter = Aliases!();
    }
    else static if(T.length == 1) {
        static if(predicate!(T[0])) alias Filter = T;
        else alias Filter = Aliases!();
    }
    else {
        mixin(FilterMixin(T.length));
    }
}



private version(unittest) {
    import mach.traits.primitives : isFloatingPoint, isIntegral;
}

unittest { /// Predicate applies to types
    static assert(is(
        Filter!(isFloatingPoint, int, float, long, double) == Aliases!(float, double)
    ));
    static assert(is(
        Filter!(isIntegral, int, float, long, double) == Aliases!(int, long)
    ));
}

unittest { /// Predicate applies to constants
    enum bool isEven(int T) = ((T % 2) == 0);
    alias evens = Filter!(isEven, 1, 2, 3, 4, 5, 6);
    static assert(evens.length == 3);
    static assert(evens[0] == 2);
    static assert(evens[1] == 4);
    static assert(evens[2] == 6);
}
