module mach.traits.attributes;

private:

import mach.traits.type : isType;
import mach.meta : Any, Filter;

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
template hasAttributeType(Type, alias symbol){
    template attributeIsType(alias attribute){
        enum bool attributeIsType = isType!(Type, attribute);
    }
    enum bool hasAttributeType = Any!(attributeIsType, getAttributes!symbol);
}

/// True when a symbol has any UDAs equal to the given value.
template hasAttributeValue(alias value, alias symbol){
    template isValue(alias attribute){
        static if(is(typeof({static if(value == attribute){}}))){
            static if(value == attribute){
                enum bool isValue = true;
            }else{
                enum bool isValue = false;
            }
        }else{
            enum bool isValue = false;
        }
    }
    enum bool hasAttributeValue = Any!(isValue, getAttributes!symbol);
}



version(unittest){
    private:
    struct TestA{}
    @("b") struct TestB{int x;}
    @(TestB(1)) @("c") struct TestC{
        @(int(1)) int x;
        @(int(0)) @(int(1)) @("") int y;
    }
}
unittest{
    static assert(getAttributes!TestA.length == 0);
    static assert(getAttributes!TestB.length == 1);
    static assert(getAttributes!TestC.length == 2);
}
unittest{
    static assert(getAttributes!(string, TestA).length == 0);
    static assert(getAttributes!(string, TestB).length == 1);
    static assert(getAttributes!(string, TestC).length == 1);
    static assert(getAttributes!(int, TestC.y).length == 2);
}
unittest{
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
