module mach.range.find.result;

private:

import std.typecons : Tuple;

public:



/// Result of a plural find operation with both an index and a value.
template FindResultPlural(Index, Value){
    alias FindResultPlural = Tuple!(Index, `index`, Value, `value`);
}

/// Result of a plural find operation with an index but no value.
template FindResultIndexPlural(Index){
    alias FindResultIndexPlural = Index;
}



/// Result of a singular find operation with both an index and a value.
struct FindResultSingular(Index, Value){
    Index index;
    Value value;
    bool exists;
    
    this(bool exists){
        this.exists = exists;
    }
    this(Index index, Value value, bool exists = true){
        this.index = index;
        this.value = value;
        this.exists = exists;
    }
    
    string toString() const{
        import std.conv : to;
        if(this.exists){
            return to!string(this.value) ~ " found at index " ~ to!string(this.index);
        }else{
            return "not found";
        }
    }
}

/// Result of a singular find operation with an index but no value.
struct FindResultIndexSingular(Index){
    Index index;
    bool exists;
    
    this(bool exists){
        this.exists = exists;
    }
    this(Index index, bool exists = true){
        this.index = index;
        this.exists = exists;
    }
    
    string toString() const{
        import std.conv : to;
        if(this.exists){
            return "found at index " ~ to!string(this.index);
        }else{
            return "not found";
        }
    }
}
