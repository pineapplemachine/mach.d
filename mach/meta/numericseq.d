module mach.meta.numericseq;

private:

import mach.meta.aliases : Aliases;

/++ Docs: mach.meta.numericseq

The `NumericSequence` template accepts a `low` argument, a `high` argument,
and an optional `increment` argument. `low` must be less than or equal to `high`,
and `increment` must be greater than zero. A sequence is produced by adding
`increment` to `low` in steps until `high` is met or exceeded.

+/

unittest{ /// Example
    // Increment by 1 from 0 until 3
    alias seq = NumericSequence!(0, 3);
    static assert(seq.length == 3);
    static assert(seq[0] == 0);
    static assert(seq[1] == 1);
    static assert(seq[2] == 2);
}

unittest{ /// Example
    // Increment by 2 from 0 until 6
    alias seq = NumericSequence!(0, 6, 2);
    static assert(seq.length == 3);
    static assert(seq[0] == 0);
    static assert(seq[1] == 2);
    static assert(seq[2] == 4);
}

public:



/// Produces a sequence of numbers at compile time.
template NumericSequence(alias low, alias high, alias increment = 1) if(
    high >= low && increment > 0
){
    static if(low >= high){
        alias NumericSequence = Aliases!();
    }else static if(low + increment >= high){
        alias NumericSequence = Aliases!(low);
    }else{
        alias NumericSequence = Aliases!(
            low, NumericSequence!(low + increment, high, increment)
        );
    }
}



unittest{
    // Empty sequence
    static assert(is(NumericSequence!(0, 0) == Aliases!()));
    static assert(is(NumericSequence!(1, 1) == Aliases!()));
}
unittest{
    // Sequence containing one entry
    alias x = NumericSequence!(0, 1);
    static assert(x.length == 1);
    static assert(x[0] == 0);
    foreach(i; x){static assert(i == 0);}
}
unittest{
    // Sequence containing multiple entries
    alias x = NumericSequence!(0, 4);
    static assert(x.length == 4);
    foreach(i, v; x){static assert(i == v);}
}
unittest{
    // Sequence not starting at zero
    alias x = NumericSequence!(-4, 4);
    static assert(x.length == 8);
    foreach(i, v; x){static assert(i == v + 4);}
}
unittest{
    // Sequence with non-default increment argument
    alias x = NumericSequence!(0, 4, 0.5);
    static assert(x.length == 8);
    foreach(i, v; x){static assert(i == v * 2);}
}
