module mach.text.str.arrays;

private:

import mach.traits : isFiniteIterable, isInfiniteIterable, isArray, ArrayElementType;
import mach.traits : isAssociativeArray, ArrayKeyType, ArrayValueType, isPrimitive;
import mach.text.str.settings;
import mach.text.str.str : str;

public:



/// Get a string representation of a finite iterable.
string iterabletostring(StrSettings settings = StrSettings.Default, RangeFrom = void, T)(
    auto ref T iter
) if(isFiniteIterable!T){
    static if(is(RangeFrom == void)) alias Type = T;
    else alias Type = RangeFrom;
    // Print "int[].[0, 1]" instead of "int[].[int(0), int(1)]".
    static if(isArray!T && settings.showarraytype){
        static if(isPrimitive!(ArrayElementType!T)){
            enum StrSettings valuesettings = StrSettings.Concise;
        }else{
            enum StrSettings valuesettings = settings;
        }
    }else{
        enum StrSettings valuesettings = settings;
    }
    // Do the stuff
    string getcontent(){
        static if(!isArray!T && is(typeof({if(iter is null){}}))){
            if(iter is null) return "null";
        }
        string result = "";
        foreach(item; iter){
            if(result.length != 0) result ~= ", ";
            result ~= str!(valuesettings, true)(item);
        }
        return "[" ~ result ~ "]";
    }
    enum showarraytype = settings.showarraytype;
    enum showiterabletype = settings.showiterabletype;
    static if(isArray!T && showarraytype){
        return settings.typeprefix!(showarraytype, Type, true, !is(Type == T)) ~ ":" ~ getcontent();
    }else static if(!isArray!T && showiterabletype){
        return settings.typeprefix!(showiterabletype, Type, true, !is(Type == T)) ~ ":" ~ getcontent();
    }else{
        return getcontent();
    }
}

/// Get a string representation of an infinite iterable.
string iterabletostring(StrSettings settings = StrSettings.Default, RangeFrom = void, T)(
    auto ref T iter, in size_t limit = 8
) if(isInfiniteIterable!T){
    static if(is(RangeFrom == void)) alias Type = T;
    else alias Type = RangeFrom;
    string getcontent(){
        static if(is(typeof({if(iter is null){}}))){
            if(iter is null) return "null";
        }
        string result = "";
        size_t count = 0;
        foreach(item; iter){
            if(count >= limit) break;
            if(result.length != 0) result ~= ", ";
            result ~= str!(settings, true)(item);
            count++;
        }
        return "[" ~ result ~ ", ...]";
    }
    enum showtype = settings.showiterabletype;
    static if(settings.showiterabletype !is settings.TypeDetail.None){
        return settings.typeprefix!(showtype, Type, true, !is(Type == T)) ~ ":" ~ getcontent();
    }else{
        return getcontent();
    }
}



/// Get a string representation of an associative array.
string arraytostring(StrSettings settings = StrSettings.Default, T)(
    in T array
) if(isAssociativeArray!T){
    // Print "int[int].[0: 1, 2: 3]" instead of "int[].[int(0): int(1), int(2): int(3)]".
    static if(settings.showassociativearraytype){
        static if(isPrimitive!(ArrayKeyType!T)){
            enum StrSettings keysettings = StrSettings.Concise;
        }else{
            enum StrSettings keysettings = settings;
        }
        static if(isPrimitive!(ArrayValueType!T)){
            enum StrSettings valuesettings = StrSettings.Concise;
        }else{
            enum StrSettings valuesettings = settings;
        }
    }else{
        enum StrSettings keysettings = settings;
        enum StrSettings valuesettings = settings;
    }
    // Do the stuff
    string getcontent(){
        string result = "";
        foreach(key, value; array){
            if(result.length != 0) result ~= ", ";
            result ~= str!(keysettings, true)(key) ~ ": " ~ str!(valuesettings, true)(value);
        }
        return "[" ~ result ~ "]";
    }
    enum showtype = settings.showassociativearraytype;
    static if(showtype){
        enum keytype = settings.typeprefix!(showtype, ArrayKeyType!T);
        enum valuetype = settings.typeprefix!(showtype, ArrayValueType!T);
        return valuetype ~ "[" ~ keytype ~ "]:" ~ getcontent();
    }else{
        return getcontent();
    }
}



version(unittest){
    private:
    alias Verbose = StrSettings.Verbose;
}

unittest{
    assert(new int[0].iterabletostring == `[]`);
    assert([0].iterabletostring == `[0]`);
    assert([0, 1, 2, 3].iterabletostring == `[0, 1, 2, 3]`);
    assert(['a', 'b', 'c'].iterabletostring == `['a', 'b', 'c']`);
    assert(["a", "b", "c"].iterabletostring == `["a", "b", "c"]`);
    assert([[0, 1], [1, 2], []].iterabletostring == `[[0, 1], [1, 2], []]`);
    assert([int(0)].iterabletostring!Verbose == `int[]:[0]`);
}
unittest{
    enum E{A, B, C}
    assert([E.A, E.B, E.C, E.A, E.B].iterabletostring == `[A, B, C, A, B]`);
    assert([E.A, E.B, E.C, E.A, E.B].iterabletostring!Verbose == `E[]:[E.A, E.B, E.C, E.A, E.B]`);
}

unittest{
    struct EmptyRange{
        enum bool empty = true;
        @property int front(){assert(false); return 0;}
        void popFront(){}
    }
    assert(EmptyRange().iterabletostring == "[]");
    assert(EmptyRange().iterabletostring!Verbose == "struct:range:EmptyRange:[]");
}
unittest{
    struct InfRange{
        enum bool empty = false;
        int front = 0;
        void popFront(){this.front++;}
    }
    assert(InfRange().iterabletostring == "[0, 1, 2, 3, 4, 5, 6, 7, ...]");
    assert(InfRange().iterabletostring!Verbose ==
        "struct:range:InfRange:[int(0), int(1), int(2), int(3), int(4), int(5), int(6), int(7), ...]"
    );
}

unittest{
    class NullableEmptyRange{
        enum bool empty = true;
        @property int front(){assert(false); return 0;}
        void popFront(){}
    }
    assert(new NullableEmptyRange().iterabletostring == "[]");
    assert(new NullableEmptyRange().iterabletostring!Verbose == "class:range:NullableEmptyRange:[]");
    NullableEmptyRange nullrange = null;
    assert(nullrange.iterabletostring == "null");
    assert(nullrange.iterabletostring!Verbose == "class:range:NullableEmptyRange:null");
}
unittest{
    class NullableInfRange{
        enum bool empty = false;
        int front = 0;
        void popFront(){this.front++;}
    }
    assert(new NullableInfRange().iterabletostring == "[0, 1, 2, 3, 4, 5, 6, 7, ...]");
    assert(new NullableInfRange().iterabletostring!Verbose ==
        "class:range:NullableInfRange:[int(0), int(1), int(2), int(3), int(4), int(5), int(6), int(7), ...]"
    );
    NullableInfRange nullrange = null;
    assert(nullrange.iterabletostring == "null");
    assert(nullrange.iterabletostring!Verbose == "class:range:NullableInfRange:null");
}

unittest{
    string[string] emptyaa;
    assert(emptyaa.arraytostring == `[]`);
    assert([0: 1].arraytostring == `[0: 1]`);
    assert(['a': 'b'].arraytostring == `['a': 'b']`);
    assert(["a": "b"].arraytostring == `["a": "b"]`);
    auto aa = [0: 1, 2: 3].arraytostring;
    assert(aa == `[0: 1, 2: 3]` ||  aa == `[2: 3, 0: 1]`);
    assert(emptyaa.arraytostring!Verbose == `string[string]:[]`);
    assert([int(0): int(1)].arraytostring!Verbose == `int[int]:[0: 1]`);
    assert(['a': 'b'].arraytostring!Verbose == `char[char]:['a': 'b']`);
    assert(["a": "b"].arraytostring!Verbose == `string[string]:["a": "b"]`);
    assert(["a"w: "b"d].arraytostring!Verbose == `dstring[wstring]:["a"w: "b"d]`);
}
