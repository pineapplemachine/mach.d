module mach.text.str.tuples;

private:

import mach.types.tuple : isTuple;
import mach.text.str.settings;
import mach.text.str.str : str;

/++ Docs

This module implements functions used by `str` to serialize tuples;
they are not intended to be called directly.

+/

public:



string tupletostring(StrSettings settings = StrSettings.Default, T)(
    auto ref T value
) if(isTuple!value){
    enum showclasstype = settings.showclasstype;
    enum showstructtype = settings.showstructtype;
    static if(is(T == class)){
        static if(showclasstype){
            if(value is null) return settings.typeprefix!(showclasstype, T) ~ ":null";
        }else{
            if(value is null) return "null";
        }
    }
    string result = "";
    foreach(index, _; value){
        if(result.length != 0) result ~= ", ";
        result ~= str!(settings, true)(value[index]);
    }
    static if(is(T == class) && showclasstype){
        return settings.typeprefix!(showclasstype, T) ~ ":(" ~ result ~ ")";
    }else static if(is(T == struct) && showstructtype){
        return settings.typeprefix!(showstructtype, T) ~ ":(" ~ result ~ ")";
    }else{
        return "(" ~ result ~ ")";
    }
}



private version(unittest){
    import mach.types.tuple : tuple;
    alias Verbose = StrSettings.Verbose;
}

unittest{
    assert(tuple().tupletostring == `()`);
    assert(tuple(1).tupletostring == `(1)`);
    assert(tuple("hello").tupletostring == `("hello")`);
    assert(tuple(1, 2).tupletostring == `(1, 2)`);
    assert(tuple(1, 2, 3).tupletostring == `(1, 2, 3)`);
}

unittest{
    assert(tuple().tupletostring!Verbose == `struct:Tuple!():()`);
    assert(tuple(1).tupletostring!Verbose == `struct:Tuple!int:(int(1))`);
    assert(tuple("hello").tupletostring!Verbose == `struct:Tuple!string:("hello")`);
    assert(tuple(1, 2).tupletostring!Verbose == `struct:Tuple!(int, int):(int(1), int(2))`);
    assert(tuple(1, 2, 3).tupletostring!Verbose == `struct:Tuple!(int, int, int):(int(1), int(2), int(3))`);
}
