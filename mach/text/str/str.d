module mach.text.str.str;

private:

import mach.types : isTuple;

import mach.traits : isNull, isBoolean, isIntegral, isFloatingPoint, isCharacter;
import mach.traits : isImaginary, isComplex, isIterable, isFiniteIterable, isArray;
import mach.traits : isString, isPointer, isEnumType, isAssociativeArray, isRange;

import mach.range.asrange : validAsRange;

import mach.text.str.arrays : iterabletostring, arraytostring;
import mach.text.str.tuples : tupletostring;
import mach.text.str.types : typetostring, typetostringtostring;
import mach.text.str.types : hasToString, hasCustomToString;

import mach.text.str.primitives;
import mach.text.str.settings;

/++ Docs

The `str` function may be used to acquire a string representation of just about
anything.
It optionally accepts a `StrSettings` object as a template argument to specify
behavior.

+/

unittest{ /// Example
    assert(str(100) == `100`);
    assert(str(1.234) == `1.234`);
    assert(str('x') == `x`);
    assert(str("hello") == `hello`);
    assert(str([1, 2, 3]) == `[1, 2, 3]`);
    assert(str(["key": "value"]) == `["key": "value"]`);
    assert(str(null) == `null`);
}

unittest{ /// Example
    enum Enum{Hello, World}
    assert(str(Enum.Hello) == `Hello`);
    assert(str(Enum.World) == `World`);
}

unittest{ /// Example
    struct MyType{
        string name;
        int x, y;
    }
    assert(str(MyType("hi", 1, -2)) == `{name: "hi", x: 1, y: -2}`);
}

unittest{ /// Example
    import mach.range : map, filter;
    import mach.text.ascii : toupper;
    auto numrange = [0, 1, 2, 3, 4, 5, 6].map!(n => n * n).filter!(n => n % 2 == 0);
    assert(str(numrange) == `[0, 4, 16, 36]`);
    auto charrange = "hello world!".map!toupper;
    assert(str(charrange) == `HELLO WORLD!`);
}

/++ Docs

The default settings show a minimum of information about the type that's being
serialized.
This default preset can be referred to with `StrSettings.Default` or
`StrSettings.Concise`. The `StrSettings.Verbose` preset includes almost all
type information. Other presets include `StrSettings.Medium` and
`StrSettings.Maximum`.

+/

unittest{ /// Example
    assert(str!(StrSettings.Verbose)(int(100)) == `int(100)`);
    assert(str!(StrSettings.Verbose)(ulong(100)) == `ulong(100)`);
    assert(str!(StrSettings.Verbose)(char('x')) == `char('x')`);
}

public:



/// Convert any input to a string.
string str(
    StrSettings settings = StrSettings.Default, bool quoteliterals = false, T
)(
    auto ref T value
){
    static if(hasCustomToString!T || (!settings.ignoreobjecttostring && hasToString!T)){
        return value.typetostringtostring!settings;
    }else static if(isNull!T){
        return "null";
    }else static if(isEnumType!T){
        return value.enumtostring!settings;
    }else static if(isPointer!T){
        return value.pointertostring!settings;
    }else static if(isBoolean!T){
        return value.booleantostring;
    }else static if(isIntegral!T){
        return value.integertostring!settings;
    }else static if(isFloatingPoint!T){
        return value.floattostring!settings;
    }else static if(isImaginary!T){
        return value.imaginarytostring!settings;
    }else static if(isComplex!T){
        return value.complextostring!settings;
    }else static if(isCharacter!T){
        return value.charactertostring!(settings, quoteliterals);
    }else static if(isAssociativeArray!T){
        return value.arraytostring!settings;
    }else static if(isString!T && isFiniteIterable!T){
        return value.stringtostring!(settings, quoteliterals);
    }else static if(isRange!T || isArray!T){
        return value.iterabletostring!settings;
    }else static if(validAsRange!T && settings.valueasrange){
        return value.asrange.iterabletostring!(settings, T);
    }else static if(isTuple!T){
        return value.tupletostring!settings;
    }else static if(is(T == struct) || is(T == class) || is(T == union)){
        return value.typetostring!settings;
    }else{
        // Shouldn't happen
        static assert(false, "Unable to stringify type " ~ T.stringof ~ ".");
    }
}



private version(unittest){
    import mach.types : tuple;
    alias Verbose = StrSettings.Verbose;
    enum Enum{Yes, No}
    struct TestStruct{string hi;}
    class TestClass{string hi; this(string hi){this.hi = hi;}}
    struct EmptyRange{
        enum bool empty = true;
        @property int front(){assert(false); return 0;}
        void popFront(){}
    }
    struct InfRange{
        enum bool empty = false;
        int front = 0;
        void popFront(){this.front++;}
    }
    struct FiniteRange{
        int front = 0;
        @property bool empty() const{return this.front < 0;}
        void popFront(){this.front--;}
    }
    struct ToStringStruct{
        string x;
        string toString() const{return this.x;}
    }
    class ToStringClass{
        string x;
        this(string x){this.x = x;}
        override string toString(){return this.x;}
    }
    struct AsRangeTest{
        int i = 0;
        @property auto asrange(){return EmptyRange();}
    }
}

unittest{
    assert(str(null) == `null`);
    assert(str(true) == `true`);
    assert(str(false) == `false`);
    assert(str(0) == `0`);
    assert(str(1) == `1`);
    assert(str(-1) == `-1`);
    assert(str(1.25) == `1.25`);
    assert(str('x') == `x`);
    assert(str('ツ') == `ツ`);
    assert(str("hello") == `hello`);
    assert(str("hello"w) == `hello`);
    assert(str("hello"d) == `hello`);
    assert(str(cast(int*) null) == `null`);
    assert(str(cast(int*)(0xABC)) == `0xABC`);
    assert(str(Enum.Yes) == `Yes`);
    assert(str(Enum.No) == `No`);
    assert(str(new int[0]) == `[]`);
    assert(str([0, 1, 2]) == `[0, 1, 2]`);
    assert(str(["x": "y"]) == `["x": "y"]`);
    assert(str(EmptyRange()) == `[]`);
    assert(str(InfRange()) == `[0, 1, 2, 3, 4, 5, 6, 7, ...]`);
    assert(str(FiniteRange(3)) == `[3, 2, 1, 0]`);
    assert(str(TestStruct("hello")) == `{hi: "hello"}`);
    assert(str(new TestClass("hello")) == `{hi: "hello"}`);
    assert(str(ToStringStruct("hi")) == "hi");
    assert(str(new ToStringClass("hi")) == "hi");
    assert(str(AsRangeTest()) == "[]");
    assert(str(tuple("x", "y")) == `("x", "y")`);
    assert(str!Verbose(AsRangeTest()) == "struct:asrange:AsRangeTest:[]");
}
