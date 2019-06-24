module mach.traits.attributes;

private:

import mach.traits.type : isType;
import mach.meta.filter : Filter;

public:



/// Get a tuple of user-defined attributes belonging to a symbol.
template getAttributes(alias symbol){
    enum getAttributes = __traits(getAttributes, symbol);
}

/// Get a tuple of user-defined attributes belonging to a symbol,
/// filtered by type.
template getAttributes(Type, alias symbol){
    template attributeIsType(alias attribute){
        enum bool attributeIsType = isType!(Type, attribute);
    }
    alias getAttributes = Filter!(attributeIsType, getAttributes!symbol);
}



/// When `attribute` is a type, determines whether a symbol has any UDAs of
/// the given type.
/// When `attribute` is a value, determines whether a symbol has any UDAs
/// equal to the given value.
template hasAttribute(alias attribute, alias symbol){
    static if(is(typeof(attribute))){
        enum hasAttribute = hasAttributeValue!(attribute, symbol);
    }else{
        enum hasAttribute = hasAttributeType!(attribute, symbol);
    }
}

/// ditto
template hasAttribute(Type, alias symbol){
    enum bool hasAttribute = hasAttributeType!(Type, symbol);
}

/// True when a symbol has any UDAs of the given type.
template hasAttributeType(T...) if(T.length == 2) {
    enum bool hasAttributeType = () {
        alias Type = T[0];
        alias symbol = T[1];
        foreach(attribute; getAttributes!symbol) {
            static if(isType!(Type, attribute)) {
                return true;
            }
        }
        return false;
    }();
}

/// True when a symbol has any UDAs equal to the given value.
template hasAttributeValue(T...) if(T.length == 2) {
    enum bool hasAttributeValue = () {
        alias value = T[0];
        alias symbol = T[1];
        foreach(attribute; getAttributes!symbol) {
            static if(is(typeof({static if(value == attribute){}})) &&
                value == attribute
            ){
                return true;
            }
        }
        return false;
    }();
}



private version(unittest) {
    struct TestA{}
    @("b") struct TestB{int x;}
    @(TestB(1)) @("c") struct TestC{
        @(int(1)) int x;
        @(int(0)) @(int(1)) @("") int y;
    }
}

unittest {
    static assert(getAttributes!TestA.length == 0);
    static assert(getAttributes!TestB.length == 1);
    static assert(getAttributes!TestC.length == 2);
}

unittest {
    static assert(getAttributes!(string, TestA).length == 0);
    static assert(getAttributes!(string, TestB).length == 1);
    static assert(getAttributes!(string, TestC).length == 1);
    static assert(getAttributes!(int, TestC.y).length == 2);
}

unittest {
    static assert(!hasAttribute!(string, TestA));
    static assert(!hasAttribute!("a", TestA));
    static assert(hasAttribute!(string, TestB));
    static assert(hasAttribute!("b", TestB));
    static assert(hasAttribute!(string, TestC));
    static assert(hasAttribute!("c", TestC));
    static assert(hasAttribute!(TestB, TestC));
    static assert(hasAttribute!(TestB(1), TestC));
    static assert(!hasAttribute!(TestB(2), TestC));
}
