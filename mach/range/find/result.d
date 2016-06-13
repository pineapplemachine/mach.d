module mach.range.find.result;

public:



/// Result of a find operation with both an index and a value.
struct FindResult(Index, Value){
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

/// Result of a find operation with an index but no value.
struct FindResultIndex(Index){
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
