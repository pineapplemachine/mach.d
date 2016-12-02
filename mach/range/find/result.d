module mach.range.find.result;

private:

import mach.types : tuple;

public:



/// Result of a plural find operation with both an index and a value.
struct FindResultPlural(Index, Value){
    Index index;
    Value value;
    @property auto astuple(){
        return tuple(this.index, this.value);
    }
    alias astuple this;
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
}
