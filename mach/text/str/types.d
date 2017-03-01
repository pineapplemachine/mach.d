module mach.text.str.types;

private:

import mach.text.str.settings;
import mach.text.str.str : str;

/++ Docs

This module implements functions used by `str` to serialize user-defined types;
they are not intended to be called directly.

+/

public:



string typetostring(StrSettings settings = StrSettings.Default, T)(
    auto ref T value
) if(is(T == struct) || is(T == class) || is(T == union)){
    enum showclasstype = settings.showclasstype;
    enum showstructtype = settings.showstructtype;
    enum showuniontype = settings.showuniontype;
    static if(is(T == class)){
        static if(showclasstype){
            if(value is null) return settings.typeprefix!(showclasstype, T) ~ ":null";
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
    static if(is(T == class) && showclasstype){
        return settings.typeprefix!(showclasstype, T) ~ ":{" ~ result ~ "}";
    }else static if(is(T == struct) && showstructtype){
        return settings.typeprefix!(showstructtype, T) ~ ":{" ~ result ~ "}";
    }else static if(is(T == union) && showuniontype){
        return settings.typeprefix!(showuniontype, T) ~ ":{" ~ result ~ "}";
    }else{
        return "{" ~ result ~ "}";
    }
}



/// Determine whether a type has a toString method other than the one
/// that comes with the Object interface, because that one is stupid.
private template hasCustomToString(T){
    static if(is(typeof({string x = T.init.toString();}))){
        static if(is(typeof({enum x = &T.toString !is &Object.toString;}))){
            enum bool hasCustomToString = &T.toString !is &Object.toString;
        }else{
            enum bool hasCustomToString = true;
        }
    }else{
        enum bool hasCustomToString = false;
    }
}

private template hasToString(T){
    enum bool hasToString = is(typeof({string x = T.init.toString();}));
}

/// lol
string typetostringtostring(StrSettings settings = StrSettings.Default, T)(
    auto ref T value
) if(hasToString!T){
    string getcontent(){
        static if(is(typeof({if(value is null){}}))){
            return value is null ? "null" : value.toString();
        }else{
            return value.toString();
        }
    }
    enum showtype = settings.showtostringtype;
    static if(showtype){
        enum showlabel = settings.showtostringlabels;
        return settings.typeprefix!(showtype, T, showlabel) ~ ":\"" ~ getcontent() ~ "\"";
    }else{
        return getcontent();
    }
}



private version(unittest){
    alias Verbose = StrSettings.Verbose;
}

unittest{
    class TestClass{string hi; this(string hi){this.hi = hi;}}
    struct ToStringStruct{
        string x;
        string toString() const{return this.x;}
    }
    class ToStringClass{
        string x;
        this(string x){this.x = x;}
        override string toString(){return this.x;}
    }
    static assert(hasToString!ToStringStruct);
    static assert(hasToString!ToStringClass);
    static assert(hasToString!TestClass);
    static assert(!hasToString!void);
    static assert(!hasToString!int);
    static assert(hasCustomToString!ToStringStruct);
    static assert(hasCustomToString!ToStringClass);
    static assert(!hasCustomToString!TestClass);
    static assert(!hasCustomToString!void);
    static assert(!hasCustomToString!int);
    assert(ToStringStruct("hi").typetostringtostring == "hi");
    assert(ToStringStruct("hi").typetostringtostring!Verbose == `struct:ToStringStruct:"hi"`);
    assert(new ToStringClass("hi").typetostringtostring == "hi");
    assert(new ToStringClass("hi").typetostringtostring!Verbose == `class:ToStringClass:"hi"`);
}

unittest{
    struct TestStruct{int x, y;}
    assert(TestStruct(0, 0).typetostring == `{x: 0, y: 0}`);
    assert(TestStruct(-1, 1).typetostring == `{x: -1, y: 1}`);
    assert(TestStruct(0, 0).typetostring!Verbose == `struct:TestStruct:{x: int(0), y: int(0)}`);
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
    assert(a.typetostring!Verbose == `class:TestClass:null`);
    assert(b.typetostring!Verbose == `class:TestClass:{x: int(0), y: int(0)}`);
    assert(c.typetostring!Verbose == `class:TestClass:{x: int(-1), y: int(1)}`);
}
unittest{
    union TestUnion{long x; int y;}
    TestUnion a; a.x = 0;
    assert(a.typetostring == `{x: 0, y: 0}`);
    assert(a.typetostring!Verbose == `union:TestUnion:{x: long(0), y: int(0)}`);
}
