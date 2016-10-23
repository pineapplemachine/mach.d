module mach.meta.numericseq;

private:

import mach.meta.aliases : Aliases;

public:



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
