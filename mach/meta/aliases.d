module mach.meta.aliases;

private:

/++ Docs: mach.meta.aliases

The `Alias` template can be used to generate an alias to a specific value,
even ones that could not be aliased using `alias x = y;` because `y` is a value
but not a symbol.

+/

unittest{ /// Example
    alias intalias = Alias!int;
    static assert(is(intalias == int));
}

unittest{ /// Example
    alias zero = Alias!0;
    static assert(zero == 0);
}

/++ md

The `Aliases` template can be used to produce an alias for a sequence of values.

+/

unittest{ /// Example
    alias seq = Aliases!(0, 1, void);
    static assert(seq[0] == 0);
    static assert(seq[1] == 1);
    static assert(is(seq[2] == void));
}

unittest{ /// Example
    alias emptyseq = Aliases!();
    static assert(emptyseq.length == 0);
}

unittest{ /// Example
    alias ints = Aliases!(int, int, int);
    static assert(ints.length == 3);
    auto fn0(int, int, int){}
    static assert(is(typeof({fn0(ints.init);})));
    auto fn1(ints){}
    static assert(is(typeof({fn1(ints.init);})));
}

public:



/// Produce an alias referring to a sequence of values.
template Aliases(T...){
    alias Aliases = T;
}

/// Produce an alias referring to a value.
template Alias(T){
    alias Alias = T;
}

/// ditto
template Alias(alias T){
    static if(__traits(compiles, {alias A = T;})){
        alias Alias = T;
    }else static if(__traits(compiles, {enum A = T;})){
        enum Alias = T;
    }else{
        static assert(false, "Failed to alias type " ~ a.stringof ~ ".");
    }
}



unittest{
    alias Nums = Aliases!(int, real);
    void numstest(Nums nums){
        static assert(nums.length == 2);
        static assert(is(typeof(nums[0]) == int));
        static assert(is(typeof(nums[1]) == real));
    }
}
unittest{
    alias Ints = Aliases!int;
    void intstest(Ints i){
        static assert(is(typeof(i[0]) == int));
    }
}
unittest{
    alias Int = Alias!int;
    void inttest(Int i){
        static assert(is(typeof(i) == int));
    }
    alias Four = Alias!4;
}
