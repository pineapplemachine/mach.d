module mach.types.value;

private:

//

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
