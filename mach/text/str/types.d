module mach.text.str.types;

private:

import mach.traits : isClass;
import mach.text.str.settings;
import mach.text.str.str : str;

public:



string typetostring(StrSettings settings = StrSettings.Default, T)(
    auto ref T value
) if(is(T == struct) || is(T == class) || is(T == union)){
    static if(isClass!T){
        static if(settings.classes){
            if(value is null) return T.stringof ~ ".null";
        }else{
            if(value is null) return "null";
        }
    }
    string result = "";
    foreach(index, Type; typeof(T.tupleof)){
        if(result.length != 0) result ~= ", ";
        enum name = __traits(identifier, T.tupleof[index]);
        result ~= name ~ ": " ~ str!(settings, true)(value.tupleof[index]);
    }
    static if(
        (is(T == class) && settings.classes) ||
        (is(T == struct) && settings.structs) ||
        (is(T == union) && settings.unions)
    ){
        return T.stringof ~ "{" ~ result ~ "}";
    }else{
        return "{" ~ result ~ "}";
    }
}



version(unittest){
    private:
    alias Verbose = StrSettings.Verbose;
}

unittest{
    struct TestStruct{int x, y;}
    assert(TestStruct(0, 0).typetostring == `{x: 0, y: 0}`);
    assert(TestStruct(-1, 1).typetostring == `{x: -1, y: 1}`);
    assert(TestStruct(0, 0).typetostring!Verbose == `TestStruct{x: int(0), y: int(0)}`);
}
unittest{
    class TestClass{
        int x, y;
        this(int x, int y){this.x = x; this.y = y;}
    }
    TestClass a = null;
    TestClass b = new TestClass(0, 0);
    TestClass c = new TestClass(-1, 1);
    assert(a.typetostring == `null`);
    assert(b.typetostring == `{x: 0, y: 0}`);
    assert(c.typetostring == `{x: -1, y: 1}`);
    assert(a.typetostring!Verbose == `TestClass.null`);
    assert(b.typetostring!Verbose == `TestClass{x: int(0), y: int(0)}`);
    assert(c.typetostring!Verbose == `TestClass{x: int(-1), y: int(1)}`);
}
unittest{
    union TestUnion{long x; int y;}
    TestUnion a; a.x = 0;
    assert(a.typetostring == `{x: 0, y: 0}`);
    assert(a.typetostring!Verbose == `TestUnion{x: long(0), y: int(0)}`);
}
