module mach.types.value;

private:

/++ Docs

The `Value` struct simply wraps a single attribute of a specified type.
The `asvalue` function may be used to obtain a `Value` from a given input.

+/

unittest{ /// Example
    Value!string x = asvalue("hello");
    assert(x.value == "hello");
}

public:



Value!T asvalue(T)(auto ref T value){
    return Value!T(value);
}

/// Wraps an arbitrary type in a struct.
struct Value(T){
    T value;
}



unittest{
    Value!int x = Value!int(0);
    x = asvalue(int(0));
}
